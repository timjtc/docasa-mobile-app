# DOCASA BLE Protocol Contract — v1.1

Status: **FROZEN** (v1.0: 2026-10-30; v1.1 ratified 2026-11-05 — D-027/D-028). Single source of
truth for the device↔app interface. Implemented by firmware Phase 2 (`docasa-air-purifier-v4.ino`)
and app Phase 3 (`lib/protocol/`); v1.1 additions (per-stage seconds, offline-history ring &
sync) target firmware `4.2.0` + app Phase-5-early build (D-028) — implementation tracked in
`docs/Development-Process.md` §11. Any change requires a `docs/Decision-Log.md` entry and a
version bump.
Source planning: `IoT-Integration-Plan.md` §3 (this contract resolves its placeholder UUIDs and
open ambiguities — see Decision-Log D-002…D-006).

---

## 1. Identity & advertising

| Item | Value |
|---|---|
| Advertised local name | `DOCASA-AirPurifier` |
| Connectable | Yes (ADV_IND), single central at a time |
| ADV payload | Flags (`BR/EDR not supported`) + complete local name (24/31 bytes) |
| Scan response | Complete list of 128-bit service UUIDs (the DOCASA telemetry service below) |
| App discovery rule | **Filter by service UUID**, not by name |
| MTU | Device imposes no requirement (all payloads ≤ ~60 B); app should still request 247 |

Advertising starts during the boot animation (BLE init is inserted before `showBootScreen()` —
pre-approved by Plan §7.6) and auto-resumes after any disconnect.

## 2. UUIDs (frozen — D-002)

| Entity | UUID |
|---|---|
| DOCASA Telemetry Service | `d0ca5a0e-975a-4408-9059-a93d3207072f` |
| — Air Quality characteristic | `d0ca5a22-27ed-4fbe-aa36-dd1ffdc66f7f` |
| — Environment characteristic | `d0ca5acb-dcfc-4d8f-8a52-b21558697f7e` |
| — System Status characteristic | `d0ca5a8f-1160-4c49-a9ee-138998d9c402` |
| — Filter Counters characteristic | `d0ca5a7a-fd2b-4dbf-932a-855cb6d3ddf0` |
| — Command characteristic | `d0ca5abd-8a7e-4412-9e96-a01d4656f3f7` |
| — Offline History characteristic (v1.1 — D-028) | `d0ca5a79-bb2b-478b-abed-9ac1441cd635` |
| Standard services | Device Information `0x180A`, Battery `0x180F` (use built-in UUIDs) |
| Reserved (unused, do not reassign) | `d0ca5ac6-5e5e-4c2b-98e9-0751bb2f6ce5`, `d0ca5a13-cb67-4cf3-978d-a1962e06e88e` |

## 3. GATT table

| Service | Characteristic | Props | Cadence |
|---|---|---|---|
| Device Information `0x180A` | Manufacturer Name String | read | — (`DOCASA`) |
| | Model Number String | read | — (`DOCASA Air Purifier`) |
| | Firmware Revision String | read | — (`FIRMWARE_VERSION`, e.g. `4.1.0`) |
| | Hardware Revision String | read | — (`ESP32-WROOM-v3`) |
| Battery `0x180F` | Battery Level `0x2A19` (uint8 %) | read, notify | 1 Hz tick when subscribed |
| DOCASA Telemetry | Air Quality (JSON, §4.1) | read, notify | 1 Hz tick + **on-change** (stage) |
| | Environment (JSON, §4.2) | read, notify | 1 Hz tick |
| | System Status (JSON, §4.3) | read, notify | 1 Hz tick + **on-change** (chg, full) |
| | Filter Counters (JSON, §4.4) | read | on-read only (app polls; no notify) |
| | Offline History (ring read, §10; v1.1) | read | on-app-request only (drain-on-connect) |
| | Command (JSON, §5) | write (with response) | on write |

Rules: **notify, never indicate**; notifies are CCCD-gated (never sent unless subscribed); BLE
callbacks set flags/buffers only — no display/LED calls (Plan §3.3); every notify payload is one
complete JSON document (UTF-8, no BOM, no trailing newline, no chunking).

## 4. Payloads — JSON v1

All payloads carry `"v":1`. Parsers MUST ignore unknown keys (forward compatibility within v1).
Key order is not guaranteed; the examples below are the canonical golden fixtures.

### 4.1 Air Quality — `{"v":1,"pm1":14,"pm25":8,"pm10":21,"st":2}`

| Key | Type | Unit | Device source (v3 variable — names frozen, incl. the `pm10Value` trap) |
|---|---|---|---|
| `pm1` | int | µg/m³ | `pm10Value` (⚠ holds PM1.0; Plan §1.2 — no rename) |
| `pm25` | int | µg/m³ | `pm25Value` |
| `pm10` | int | µg/m³ | `pm100Value` |
| `st` | int | 1–5 | `overallStage` (1 GOOD · 2 FAIR · 3 POOR · 4 BAD · 5 HAZARD) |

### 4.2 Environment — `{"v":1,"t":24.6,"h":47.2,"voc":38.4}`

| Key | Type | Unit | Source | Format |
|---|---|---|---|---|
| `t` | float | °C | `temperature` | 1 decimal |
| `h` | float | % RH | `humidity` | 1 decimal |
| `voc` | float | kΩ | `gasResistance` (raw proxy — qualitative, Plan §4.5) | 1 decimal |

### 4.3 System Status — `{"v":1,"fan":3000,"bat":84,"chg":0,"full":0,"vb":15.31}`

| Key | Type | Unit | Source | Notes |
|---|---|---|---|---|
| `fan` | int | RPM | `currentFanRpm` | **Commanded target** (0/1000/2000/3000/4000), forever — a future measured-RPM key would be a new additive key `rpm`, never a repurpose of `fan` |
| `bat` | int | % | `batteryPct` | |
| `chg` | 0/1 | — | `isCharging` | |
| `full` | 0/1 | — | `isTrulyFull` | |
| `vb` | float | V | `smoothedVoltage` | 2 decimals |

### 4.4 Filter Counters — `{"v":1,"fs":10800000,"pwfs":74250000,"on":3210}` · v1.1 adds `"st"`

| Key | Type | Unit | NVS key (namespace `docasa`) | Meaning |
|---|---|---|---|---|
| `fs` | uint64 | RPM·s | `fanSec` | Σ commanded-RPM × dt |
| `pwfs` | uint64 | RPM·µg·s | `pwfs` | Σ commanded-RPM × PM2.5 × dt (load integral) |
| `on` | uint32 | h | `onSec` (seconds; hours derived) | Powered time (device lifecycle — **not** reset by `resetFilter`) |
| `st` | uint32[5] | s | `st1`…`st5` | Σ seconds spent in each air stage (0-based array: index 0 = stage 1 GOOD … index 4 = stage 5 HAZARD), **since last `resetFilter`** (v1.1 — D-027) |

Notes: both integrals are uint64 end-to-end (D-004 — the Plan's u32 `fanSeconds` overflows in
~12 days at max speed). Consumers must use 64-bit ints (Dart native: OK; JS/web: not a target —
7.20). The redundant `rt` key from Plan §3.4 is dropped (D-004). `"st"` is additive (v1.1,
D-027); older firmware omits it and parsers MUST tolerate its absence — the app then falls
back to the load-based health computation until firmware ≥ 4.2.0 is flashed. Dirty-air
exposure (health basis, D-027) = `st[2] + st[3] + st[4]` (POOR/BAD/HAZARD seconds).

### 4.5 Startup values

Until the first sensor reads (~1–2 s after boot): PM = 0, `t`/`h`/`voc` = 0.0, `st` = 1.
The app may render these as-is; there is no explicit "booting" flag in v1.

## 5. Commands (phone → device, JSON v1, write-with-response)

| Command | Effect | Ack model |
|---|---|---|
| `{"cmd":"resetFilter"}` | Zeroes `fanSec` + `pwfs` + `st` (v1.1) (`onSec` preserved) and **persists immediately** (a cut right after replacement cannot resurrect counters from the 5-min throttle window). After physical filter replacement. | GATT write ACK; app MUST re-read Filter Counters and confirm zeros |
| `{"cmd":"time","epoch":1769472000}` | Stores volatile epoch (uint32, unix seconds). Re-sent on **every** connect (Plan §5). Device epoch is untrusted across reboots (7.13). | GATT write ACK |
| `{"cmd":"offlineLog","after":4100}` (v1.1) | Arms the Offline History read cursor (§10): `after` = the last window slot the app consumed **for this bootId**; device drains slots > `after` up to head. Absent `after` → drain from oldest. App-initiated; only on connect. | GATT write ACK |
| `{"cmd":"setUsage","fs":…,"pwfs":…,"on":…,"st":[…]}` (v1.1 dev channel — D-030) | Developer-options channel: REPLACES the usage counters (`fs`/`pwfs` u64, `on` hours, `st[5]` seconds) with the seeded story; persisted to NVS immediately. Gate behind security at v1.2 (D-010). | GATT write ACK |

Error semantics (v1/v1.1): unknown commands, unknown keys, malformed JSON, missing fields
(e.g. `time` without `epoch`, `offlineLog` with non-integer slot) → **ignored silently,
connection stays up**, logged to Serial. No error characteristic. `{"cmd":"fan",...}` does not
exist (Plan §1.4 restricted list).

## 6. Behavioral semantics

1. **Handshake on connect (app-side, recommended order):** request MTU 247 → read DIS
   (log Firmware Revision) → read Battery + Air Quality + Environment + System Status +
   Filter Counters (snapshot) → write `time` → subscribe to all notify characteristics →
   **offline-history catch-up** (v1.1, §10): `offlineLog` with the app's stored water-mark for
   the reported `bootId` → drain the Offline History characteristic until exhausted.
   The drain is app-paced GATT reads; it is the ONLY moment history is pulled — no polling,
   no periodic notify.
2. **Cadence:** one 1 Hz scheduler tick inside `loop()` drives accumulation + notifies
   (never timers in BLE callbacks — Plan §3.3).
3. **On-change extras:** stage transition → immediate Air Quality notify; `chg`/`full`
   transition → immediate System Status notify.
4. **Single central:** second concurrent connection attempt is rejected (Plan §7.9).
5. **Disconnect:** advertising resumes automatically; app reconnects with exponential backoff
   (0.5 → 8 s cap).
6. **Connect during boot:** supported — advertising precedes `showBootScreen()`.
7. **Time authority:** the phone is the only clock; all history timestamps are app-side.

## 7. Versioning rules

- `"v":1` mandatory in every payload and command.
- Additive keys within v1 are allowed without a bump (parsers MUST ignore unknown keys).
- Key removal / type change / semantic change = protocol **v2** — requires a Decision-Log entry
  and dual-version support in the app codec (Plan §7.12).
- Firmware compatibility is signalled by `v`, not by the Firmware Revision string.

## 8. Golden test fixtures (normative)

Valid — must decode exactly:

| # | Characteristic | Fixture |
|---|---|---|
| F1 | Air Quality | `{"v":1,"pm1":14,"pm25":8,"pm10":21,"st":2}` |
| F2 | Environment | `{"v":1,"t":24.6,"h":47.2,"voc":38.4}` |
| F3 | System Status | `{"v":1,"fan":3000,"bat":84,"chg":0,"full":0,"vb":15.31}` |
| F4 | System Status (fan off, stage 1) | `{"v":1,"fan":0,"bat":7,"chg":1,"full":0,"vb":13.62}` |
| F5 | Filter Counters | `{"v":1,"fs":10800000,"pwfs":74250000,"on":3210}` |
| F8 | Filter Counters (v1.1) | `{"v":1,"fs":10800000,"pwfs":74250000,"on":3210,"st":[20100,60100,30120,9120,15]}` |
| F6 | Command | `{"cmd":"resetFilter"}` |
| F7 | Command | `{"cmd":"time","epoch":1769472000}` |
| F9 | Command (v1.1) | `{"cmd":"offlineLog","after":4100}` |

Invalid — must be tolerated without error:

| # | Side | Fixture | Expected behavior |
|---|---|---|---|
| X1 | device | `not json` | ignore, stay connected |
| X2 | device | `{"cmd":"fan","rpm":3000}` | ignore (restricted command) |
| X3 | device | `{"cmd":"time"}` | ignore (missing epoch) |
| X4 | app | `{"v":2,"pm1":5,...}` | protocol-mismatch state surfaced to UI |
| X5 | app | `{"v":1,"pm1":5,"unknown":9}` | decode fine, ignore unknown key |
| X6 | app | `{"v":1,"pm1":-1,"pm25":8,"pm10":21,"st":0}` | decode; UI clamps/flags invalid domain |
| X7 | app | F5 without `"st"` (pre-4.2.0 firmware) | decode fine; exposure-based health unavailable → app falls back to load-based (D-027) |
| X8 | app | F8 with a short/overlong `st` array, or non-integer entries | decode "st" missing-on-error semantics: ignore key, health falls back per X7 |
| X9 | device | `{"cmd":"offlineLog"}` with `"after"`: non-integer | ignore (malformed) |

Offline-history window record (binary, not JSON — layout is normative, see §10):
unknown/trailing bytes in a record chunk MUST be ignored/rejected at record granularity, not
crash the parser.

## 9. Reserved for v1.2

- Security pairing effects on the Command characteristic (D-010 ruling pending).
- Anything beyond §4/§5/§10 of v1.1 content (e.g. measured-RPM, OTA, cloud) stays out of v1.1.

## 10. Offline history — envelope ring & bulk sync (v1.1 — D-028)

The device records history **independently of any connection**, so app-recorded gaps
(disconnects, power-off *without* phone reaching it — power-off still ends the current window)
no longer blank the charts. The phone pulls the ring at connect ONLY (no polling, no notify).

### 10.1 Record shape — one 16 B struct per 10-min window

| Offset | Field | Type | Meaning |
|---|---|---|---|
| 0 | `pmMin` | u16 LE | min PM2.5 in the window (µg/m³) |
| 2 | `pmMean` | u16 LE | mean PM2.5 (µg/m³) |
| 4 | `pmMax` | u16 LE | max PM2.5 (µg/m³) |
| 6 | `stSec[0..4]` | 5 × u16 LE | seconds in contract stages 1–5 (GOOD…HAZARD) |

Little-endian, no header field per record (length is fixed), 16 B. Slot = 10-min window index
since boot (slot *i* ends at *(i+1)×600 s* uptime). In-flight (not-yet-complete) windows are
never exposed — a power cut loses at most the current window.

### 10.2 Storage — dedicated flash ring (resolves risk 7.19)

Custom partition CSV (`firmware/docasa-air-purifier-v4/partitions.csv`, `docasa_ring`,
256 KB `data/0x40`): ≈ 8,640 records × 16 B ≈ **138 KB per 60 days**, ~2× runway for
wear-levelling slack → **runway ≈ 4.6 months** before the oldest slot is overwritten; wrap is
detectable via a slot discontinuity vs the reported `first`. Requires a maintainer reflash
(firmware/README procedure).

### 10.3 Sync protocol (app-initiated, connect-time only)

1. After the §6.1 handshake, the app writes `{"cmd":"offlineLog","after":<slot>}` — its stored
   water-mark for the device's current `bootId` (u32 NVS boot counter); `"after"` omitted →
   drain everything available.
2. First read of the Offline History characteristic returns ring status JSON:
   `{"v":1,"boot":12345,"first":4100,"count":8639}` (`count` = slots available after the
   cursor). App updates/refreshes its `(bootId → slot → phone wall-clock)` anchor at this point
   — phone stays the only time authority (Plan §7.13); each connect re-anchors drift from the
   live 1 Hz stream.
3. Subsequent reads return packed records in slot order, up to ⌊(MTU−1)/16⌋ per read
   (15 records at MTU 247); cursor advances; an empty read (0 B) = drained. Read errors/no
   cursor armed → empty reads; the cursor lives per connection and is never persisted.
4. Cost model: 60 days unsynced ≈ 577 reads at MTU 247 (seconds, once); fully-synced connect =
   exactly the status read. No further interaction until the next connect.

Golden X-rule (§8): record chunks are consumed at record granularity; unknown bytes in a
chunk are rejected per-record, never parse-crash the phone app.
