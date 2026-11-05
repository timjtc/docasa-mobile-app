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

---

## Task 5 (2026-11-05, same session): flash-safety double-check (user request) — one real bug fixed

The user asked to verify nothing breaks when the new firmware is flashed, what NVS holds, and
whether new drivers are needed. Evidence collected on THIS host (purifier plugged into COM15):

1. **On-flash proof, pre-flash**: esptool `read_flash 0x8000 0x1000` on COM15 read the live
   partition table (MAC `20:50:0d:07:21:f8`; purifier's BT base). Decoded rows: `nvs
   @0x9000/0x5000`, `otadata @0xe000/0x2000`, app0/app1/spiffs/coredump (Default-4MB scheme,
   as v4.1.1 flashed). The v5 `partitions.csv` keeps **nvs + otadata byte-identical** → any
   plain upload preserves the Phase-1 NVS counters without reinterpretation. `docasa_ring`
   @0x200000/0x40000 overlays the never-used old spiffs region.
   Post-flash boot: stale `otadata` names "ota_0" which no longer exists in the new table →
   ROM falls back to the **factory app @0x10000** (exactly where the new build sits);
   boot confirmation is a bench checklist item.
   ⚠ Rule recorded for the maintainer: never run `erase_flash`/`erase_region` over NVS —
   plain upload is preserving; a full erase resets the filter counters (data loss).
2. **NVS contents clarified (documented for correctness)**: NVS holds only the counter set —
   `fanSec`(u64), `pwfs`(u64), `onSec`(u32), `st1..st5`(u32 ×5, since replacement), `boot`
   (u32, +1/boot) — ~9 keys, <1 KB, 5-min throttle (+ immediate persist on resetFilter).
   The 60-day AIR-QUALITY SERIES never touches NVS: it lives in the 256 KB `docasa_ring`
   partition, 16 B per 10-min window (16,384 slots = 114-day capacity, 144/day → 138 KB/60 d);
   NVS would thrash under that write pattern.
3. **Bug found & fixed during the double-check**: the offline-drain first-valid scan walked
   slot-by-slot with 16-B flash reads INSIDE the BLE read callback — a from-oldest sync
   (fresh install / stale cursor) could block the NimBLE host task for seconds and trip the
   connection supervision timeout. Rewrites: `docasaOfflineFirstValid` now scans page-granular
   (one 4-KB read = 256 slots); the read callback serves ≤ min(15, page-remaining) records and
   touches at most one page per GATT read; the two 4-KB page buffers consolidated into one
   shared `docasaRingPageBuf` static (host-task-only, no writer race). Cursor-advance now
   jumps to the resolved `first` slot after the status read (holes below are skipped, per
   §10.3 "first" semantics).
4. **Gates after the fixes (fw-build-v42c)**: compile **736,655 B flash (56%) / 44,828 B RAM
   (13%) / 0 warnings** (two-buffer build was 48,924 — consolidation reclaimed ~4 KB); diff
   gate **PASS — 602 added / 0 removed** vs the frozen v3 baseline.
5. **Drivers**: no new ones — the same USB-serial stack used for v4.1.1 already enumerates the
   device on this host (esptool completed a full handshake on COM15). The one quirk: the CLI
   *monitor* subcommand mis-resolves the user-home in some shells (C:\Windows temp error) —
   harmless for flashing; serial observation at the bench can use any terminal at 115200.

## Task 6 (2026-11-05): app side of the D-027/D-028 batch — analyzer/71-test green, verified over the air

Code (analyzer 0 issues, **71/71 tests**, +17 new):

- **Protocol**: `FilterCounters.stageSeconds` (§4.4 "st", empty on pre-v1.1/X7-X8);
  `OfflineWindowSample`; `DocasaCodec.decodeOfflineRecord` (16 B LE, §10.1 domain validity →
  torn writes throw → drain stops there); encode includes st when present; contract constants
  (`offlineUuid`, record bytes, window length).
- **Offline sync**: transport `lib/ble/fbp/fbp_offline_sync.dart` (arm → status JSON →
  drain-until-empty-or-bound; termination on `first`+`count`/empty/first-invalid) + service
  `lib/data/offline_sync.dart` (per-connect trigger off the connection state; water-mark KV
  `sync.<bootId>` = `slot|anchorMs`; anchor = phoneNow − endSlot·600 s, re-anchored every
  connect; ingest into `device_windows` idempotently; graceful degradation to the pre-v1.1
  view on any error; D-020-style debugPrint trail).
- **Schema v2**: `device_windows` (PK `(bootId,slot)`, phone-clock `windowStartMs`) + migration
  (`onUpgrade` v1→v2 creates it); compactor prunes it at the 90-day hour tier.
- **History merge**: `HistoryRepository.load` unions offline windows into PM2.5 bucket gaps —
  app-recorded minutes always win; window PM mean + proportional stage split spread by overlap
  seconds into day/week/month buckets and the donut; device-unmeasured metrics (temp/hum/voc/
  fan/batt) stay honest gaps.
- **Filter health**: `FilterBasis.dirtyAir` (installed default; `st[2..4]` vs the 1000 h
  placeholder budget) with `FilterSensitivity` (Relaxed 1.5×/Normal 1.0×/Sensitive 0.5×)
  applied to both bases; D-018 budget text fields REMOVED from the Filter page (numbers stay
  code-side) — the page now toggles basis + sensitivity (persisted `filter.basis` /
  `filter.sensitivity`); dirty-rate projection via `estimateDirtyRatePerDay`; the counters
  card shows the dirty-hours row + the stage share row straight from the device.
- Tests: offline decode (F8/F5/X7/X8 + §10.1 torn-write rejection), dual-mode health +
  multiplier math + X7 fallback, merge/ingest/watermark round-trips + compactor prune,
  widget-level basis toggle.

Over-the-air verification (A34, rebuilt + reinstalled BLE-test artifact):
- v4.2.0 + new artifact: picker → CONNECTED (live PM2.5), `handshake … fw=4.2.0`;
  Filter page shows the dirty-air rows from live counters (`1369s · 1034s …`, dirty 0.0 h,
  projected replacement via the dirty rate); History Day view shows the ring-imputed span
  bridging 16:00→connect with only the open window as the trailing gap; FBP trail:
  `FBP: offline sync — boot=5 +1 windows (watermark 1)` — exactly the device's single closed
  window, water-mark persisted.

## Task 7 (2026-11-05, same session): advertised-name fix (D-029) — Contract §1 conformance

User report: no name in ADV (picker row title blank; nRF Connect shows N/A). Root: NimBLE 2.x
advertises NO name by default (a v4.1.0-era regression vs §1's "Flags + complete local name" —
it predates the reflash). Fix: additive `adv->setName(DOCASA_BLE_NAME)` before `adv->start()`.
Gates: compile 736,943 B (56%) / 44,828 B RAM (13%) / 0 warnings; diff gate PASS. Reflashed
live (NVS + ring persisted through the cycle); the picker now renders `DOCASA-AirPurifier`.
