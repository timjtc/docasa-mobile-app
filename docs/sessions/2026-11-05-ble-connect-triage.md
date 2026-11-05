# Session log — 2026-11-05: BLE "Connecting" hang triage (Windows host, post-handoff)

Task: app selects `DOCASA-AirPurifier` in the picker → CONNECTING indicator spins forever.
Authority: docs/Development-Process.md §11 next-step (1), D-019/D-020 playbook: 3-layer probe —
device Serial, nRF Connect G2 checklist, app `logcat -s flutter` FBP trail. This session ran the
**logcat layer** live. **RESOLVED — root cause found app-side, fixed, verified end-to-end on the
device (D-025).** Serial/nRF layers (G1/G2 formalities) remain owed to the bench.

## Procedure (methodically executed)
1. Repo re-analysis on new host: graphify queries for BLE connect flow + dashboard/picker;
   read Development-Process.md, App-ADB-Test.md, Decision-Log (D-015…D-024), Bench-Runbook.md,
   BLE-Protocol-Contract.md §1–§6; FBP transport + picker + providers + gate UI sources; firmware
   GATT source (v4.1.1 — DIS strings + READ|NOTIFY properties per Contract).
2. Force consistency (as ordered): `flutter analyze` baseline → rebuilt the BLE-test artifact
   (`tools/build-ble-test-apk.sh`) → `adb install -r releases/docasa-ble-test-20261105.apk`
   onto the Samsung A34 (RFCW303YC7M; re-authorized after `adb kill-server` restart).
3. Live capture: `adb logcat -c` → full capture to tmp file → cold start → picker → picked the
   purifier → recorded the FBP decision trail (raw log retained in msys tmp, not committed).
4. Findings + fix + re-verification below; gates: analyze 0 issues, 54/54 tests, Decision-Log
   D-025, session artifacts in the APK name (same-dated artifact rebuilt post-fix).

## Findings

- **Failing stage pinpointed by the trail (pre-fix build):** BLE radio/stack fully healthy —
  `connect` (cached "already connected"), `requestMtu` 247 → GATT_SUCCESS, `discoverServices`
  → **5 services, GATT_SUCCESS** (twice per cycle: `_handshake` then `readDeviceInfo` both
  rediscover) — then `FBP: link failed: Bad state: No element` at
  `FbpDocasaConnection.readDeviceInfo.read` (line 211). FBP backoff loop then restarted forever
  → permanent CONNECTING + spinner (every failure stage maps to the same UI, as suspected in
  App-ADB-Test.md session 3).
- **Root cause (app-side):** `readDeviceInfo` compared runtime characteristic UUIDs against the
  Contract's **short-form** constants with plain string equality:
  `c.uuid.str128 == uuid` where `uuid` = `'2A29'`… but `str128` on Android always returns the
  full 128-bit normalized form (`'00002a29-0000-1000-8000-00805f9b34fb'`). Never equal → the
  FIRST DIS read threw → handshake died on every connect. The custom telemetry UUIDs in
  `contract.dart` are stored full-form, which is why scanning (`service §D-002` row) worked and
  only DIS reads died. Never hit before because D-019/D-020 practice rounds had zero DOCASA
  advertisements (no hardware powered).
- **Firmware exonerated:** 5 services incl. `180A` with 2A29/2A24/2A26/2A27 READ values
  (`DOCASA` / `DOCASA Air Purifier` / `4.1.1`) matching Contract §3 and the D-020(b)
  verification predicate; confirmed over the air post-fix (handshake device info line).
- **Evidence trail (fixed build, pid 2882):**
  ```
  FBP: state → connecting
  FBP: handshake device info: mfg=DOCASA model=DOCASA Air Purifier fw=4.1.1
  FBP: handshake done (CCCDs subscribed), link live
  FBP: state → connected            (pick → connected ≈ 1.4 s)
  FBP: first complete frame decoded
  ```
  Screen: CONNECTED badge + live PM2.5 36 / PM1.0 24 / PM10 43 µg/m³, stage POOR, "live ·
  updated 14:28".

## Fix (D-025)

`lib/ble/fbp/fbp_docasa_connection.dart` `readDeviceInfo().read()`: compare via
`c.uuid == Guid(uuid)` (FBLP `Guid ==` normalizes short-form to full 128-bit, lowercase map).
One-line change; missing-characteristic behavior unchanged (`StateError` → backoff loop, as
designed for wrong-device rejection). Telemetry UUID comparisons use full-form constants on
both sides and are left untouched.

## Follow-ups
- G4 checklist remainder on the phone (walk-away disconnect → backoff reconnect; history
  survives restart; filter-health % plausible; time sync each connect — the last two are now
  observable indirectly via Device/Filter pages) → `gate-reports/G4.md`.
- G1/G2 formalities still owed to the bench (Serial + nRF Connect) — the over-the-air
  handshake read of fw 4.1.1 is strong evidence but not the formal gate.
- After G4: restore `withServices` scan filtering + consider kDebugMode-gating the trail
  (D-020d/D-019 notes unchanged).

---

## Task 2 (2026-11-05, same session): History light-mode chart theming — D-026

Report: in light mode the History line chart showed dark-mode-colored tooltip and axis labels
(text/numbers invisible).

Analysis (fl_chart 1.3.0 source, not guessed):
- Axis labels: `_axisStyle` was hard-coded `Colors.white54` (invisible on the light card).
- Tooltip: the chart never configured `LineTouchData`, so fl_chart's defaults applied —
  bubble `Colors.blueGrey.darken(15)`, text tinted the LINE color (`cs.primary`), which in
  the light scheme resolves pale → unreadable on the dark bubble.

Fix (theme-derived, both modes build-time correct):
- `_axisStyle` → `Theme.of(context).colorScheme.onSurfaceVariant`.
- Explicit `LineTouchTooltipData`: bubble `cs.primaryContainer`, item text
  `cs.onPrimaryContainer` (bold 14, raw `s.y.toString()` parity with the old default).

Runtime verification on the phone (BLE-test artifact rebuilt + reinstalled; Day/PM2.5):
- Light: axis numbers dark on card ✓; hold-press → cyan container bubble, dark bold numbers ✓.
- Dark: axis light ✓; bubble dark-teal with light numbers ✓ (house accent family; differs
  from the old neutral blueGrey only in hue).
- Capture trick (this phone): fast `input tap` never shows the tooltip (it clears on
  touch-up); use `input swipe X Y X Y <long-dur>` as a press-hold and screencap mid-hold.
- Gates: analyze 0 issues, 54/54 tests.

---

## Task 3 (2026-11-05, same session): filter-math simplification + gapless offline history — plans ratified (D-027/D-028)

Panel-demo requirements from the user → decisions recorded in D-027 (filter-replacement basis)
and D-028 (offline-history batch + contract v1.1). Contract bumped **v1.0 → v1.1** in this session
(docs only; code follows the §11 build plan):

- Filter basis: **dirty-air hours** (POOR/BAD/HAZARD seconds since replacement — v1.1 `"st"`
  array on Filter Counters, `st[2..4]`), toggleable vs load-based (`pwfs`); basis switch is a
  UI toggle, no data surgery. Sensitivity = **budget multiplier** (Relaxed 1.5× / Normal 1.0× /
  Sensitive 0.5×) shared by BOTH methods; replaces the editable budget text fields; exposure
  basis is the installed default; pre-4.2.0 firmware falls back to load-based (no `"st"`).
- Offline (gapless) history: device-side **10-min envelope window records** (16 B: PM
  min/mean/max u16 + per-stage seconds 5×u16, ~138 KB per 60 days) in a dedicated 256 KB
  `docasa_ring` partition (resolves risk 7.19), pulled by the app at connect only via the new
  Offline History characteristic + `{"cmd":"offlineLog","after":N}` cursor command (§10);
  phone stays the time authority — `(bootId, slot) → wall-clock` anchoring, re-anchored every
  connect. No polling, no notifies; synced-up connect costs one status read.
- Firmware lands in a **NEW sketch** `firmware/docasa-air-purifier-v5/` (byte-identical seed
  from the frozen `v4/` — user decision recorded in D-028e; v4 stays 4.1.1 forever), with
  `partitions.csv` in the same dir; the one maintainer reflash session ships BOTH features,
  and is the moment to run the long-deferred G1/G2 formalities.
- Batched into one reflash deliberately: the partition change needs a flash anyway; separating
  the features would cost a second bench session for zero benefit.

Deferred by decision: security/pairing (D-010) → contract §9 (v1.2); real-cartridge budget
numbers (D-011 placeholders remain; the multiplier makes demo tuning a one-tap affair).

---

## Task 4 (2026-11-05, same session): firmware v4.2.0 — code-complete, gates green (D-028)

New sketch `firmware/docasa-air-purifier-v5/` (byte-identical v4 seed; v4 stays frozen at
4.1.1, D-028e), plus `partitions.csv` alongside it. Implementing Contract v1.1:

- **Additions (261 insertions over the v4 parent; v3-baseline gate: 580 added / 0 removed/
  changed — PASS):** `esp_partition.h` include; Offline-UUID + ring constants; GATT pointer +
  drain-cursor statics; ring module (`docasaRingBegin` — partition find data/0x40 + NVS
  boot-counter `boot`; `docasaRingValid` — sensor-domain check doubles as the torn-write
  marker, no checksum needed; `docasaRingRead`; `docasaRingWinClose` — 16 B LE record with
  erase-ahead on 4 KB page transitions ≈ 1 erase per 2.56 days; `docasaRingTick` — 1 Hz slice
  attributing seconds to the global st counters (reset by resetFilter) AND the in-flight
  envelope window (never reset); `docasaOfflineArm`; `docasaOfflineFirstValid`;
  `DocasaOfflineReadCallbacks` — status JSON `{"v","boot","first","count"}` on the first read
  after arming, ≤15×16 B packed records per read, empty body = drained, stop-at-first-invalid;
  `docasaBuildFilterCountersFull` + `docasaPublishFilterFull` — `"st"` array (§4.4) into a
  dedicated 192 B buffer so the shared v1 `buf[96]` is never touched), plus the four
  pre-approved insertion points (setup/loop untouched), `offlineLog` command branch
  (absent → oldest; malformed-after → ignore per X9), `resetFilter` zeroes+persists st,
  serial dump now shows `st=[…] dirtyH=… ringHead=…`, disconnect disarms the cursor.
- **Only modified existing line: `DOCASA_FW_VERSION` → `"4.2.0"`** (v4-owned line, invisible
  to the v3-baseline gate; v4→v5 delta confirmed: 261 insertions, 1 changed line).
- **Partition table verified byte-accurate** (`docasa-air-purifier-v5.ino.partitions.bin`):
  nvs / otadata / app factory 0x1F0000 / docasa_ring type 0x01 subtype **0x40** size
  **0x40000** — matches §10.2 exactly.
- **Gates:** compile
  `arduino-cli compile --fqbn esp32:esp32:esp32 --build-property "build.partitions=partitions.csv"
  --build-path <tmp>/fw-build-v42 firmware/docasa-air-purifier-v5` → **736,623 B flash (56%),
  40,732 B RAM (12%), 0 warnings** (v4.1.1 was 733,019/40,444 — +3.6 KB ring code). No menu
  value for custom partitions in core 3.3.12 — the build-property route is the recorded shape.
- **Tool hardening:** `firmware-diff-check.sh` — active-sketch arg (default v5), `--verbose`
  flag no longer swallowed, and a `git diff --no-index` fallback (standalone `diff` is missing
  on stock Windows shells; also no longer writes /tmp, which is unreadable in some shells).
- Runtime verification (partition find, ring write/roll, offline drain over the air, reset
  zeroing st) happens at the bench reflash session (D-028 plan) — code is analyzer/gate-green
  per the Phase-4-prebuild pattern (D-017).
