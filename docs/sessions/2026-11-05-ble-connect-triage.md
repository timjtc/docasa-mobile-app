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

## Task 8 (2026-11-05, same session): dev options + demo chain (D-030) — verified LIVE end-to-end

User requirements implemented and exercised on the phone (all screenshots in tmp):
1. **Sensitivity slider (3 stops)** — the Filter page's segmented control became a Slider
   (Relaxed/Normal/Sensitive labeled under the track; changes persist). Verified live:
   tap-Normal → **4 %** under the seeded story (960 h / 1000 h) with the alert modal firing
   immediately (threshold 10 %); Sensitive → **0 %**.
2. **TwoMonthSeeder (D-030)** — minute-cadence direct aggregate seeding (~57k rows instead of
   3.4M raws), deterministic dirty-skew (≈85 % POOR+ minutes), device "off" overnight,
   REPLACES the timeline, returns UsageTotals (fs/pwfs/on/st[5]).
3. **Dev options + 7-tap** — `DevOptionsNotifier` (KV `ui.devOptions`) + `DevTapTracker`
   (unit-tested); the section renders ONLY when on, own Switch disables; verified by driving
   7 taps on 'Device information'.
4. **Device-counter dev channel (firmware v4.2.1)** — `{"cmd":"setUsage",fs,pwfs,"on","st"}`
   validated + NVS/RAM write + persist; both transports echo it (FBLP over the air; the fake
   mutates its generator state). Verified over the air: the Device page read back the seeded
   totals right after seeding (762 h / 960 h).
5. **Seeding resets the D-021 daily cap** (lastAlertMs/filterAlertAckMs → 0) so the demo
   prompt re-arms every seeding (user's "prompt immediate replacement" requirement).
6. Immediate alert on sensitivity change fires `RecordingService.evaluateNow()` (public).

RESIDUAL for the next bench: the seeded numbers leave Normal at 4 % by design (so sliding to
Sensitive lands CLEAN at 0 %); st totals drift with post-seed live deltas (real wins).

## Task 9 (2026-11-07): demo story tuned — realistic filter-life curve (D-031)

User request: replace the all-dirty 2-month skew with a realistic texture — GOOD and FAIR
stretches present, majority still dirty, landing NEAR 0 % on the NORMAL basis so the
replacement prompt fires without touching the sensitivity.

Tuned `TwoMonthSeeder`:
- Duty: purifier sleeps only ~6 h (off 00:30–06:30 — realistic 18 h/day → ~1080 h over the
  window) — headroom for the clean stretches while the dirty budget still saturates.
- Hour bias: hours 07–09 & 21–22 tilt toward calm (GOOD/FAIR more likely); 12–18 tilt into the
  afternoon smog peak (BAD/HAZARD). Bands: GOOD 2 % / FAIR 6 % / POOR 15 % / BAD 52 % /
  HAZARD 25 % of minutes.
- Result (deterministic seed 7): Normal basis ≈ **1.51 %** — inside the 10 % alert threshold,
  so the replacement prompt fires on the NORMAL default as requested; Sensitive still 0 %.
- Tests tightened: Normal pct ∈ (0, 10); dirty-dominance + counter consistency + Sensitive
  overflow assertions stay.

Gates: analyze 0 issues, 74/74 tests; artifact rebuilt as
`releases/docasa-ble-test-20261107.apk` (date-stamped; the 20261105 artifact remains for the
older install case). Phone re-attach needed for the final on-device seeding check.


## Task 10 (2026-11-07): Demo artifact refreshed (no-prototype panel path)

User asked for the demo (non-BLE) build carrying all session changes (dev options, seed-2-
months, slider, dirty-air basis) — the features are transport-agnostic and the fake transport
echoes `setUsage` (D-030).

- `tools/build-demo-apk.sh` → `releases/docasa-demo-20261107.apk` (date-stamped; kept local
  per convention).
- Phone install required `adb uninstall com.example.docasa_app.demo` first: the previously
  installed Demo came from the pre-handoff host and carried a different signing key
  (INSTALL_FAILED_UPDATE_INCOMPATIBLE). Note for future host moves: site-loaded variants
  need a fresh install after a host key change (the parallel-install app ids are the best
  local scope for this).
- Verified on the phone: 7-tap → Developer options → Seed demo data (2 months) → immediate
  "Filter needs replacing — Filter health is at 1 %" modal (Normal basis; the seeded story
  lands near 0 by D-031 design); dismissed with "later time"; Filter page shows the slider
  (Normal) + basis toggle + the seeded story; History exposes the 2-month timeline.
- Demo nuance for the panel: the fake transport's Device information reports the emulator
  fw string ('4.1.0') — cosmetic, tagged in the banner card as the built-in emulator.

## Task 11 (2026-11-07, committed pre-handoff): History-tab revision — Last month (calendar) + month compare

Implemented and test-locked (analyzer 0 issues, **78/78 tests**, +4 new):

- **HistoryRange.lastMonth** — a calendar-bounded range (the previous complete month,
  hour-aligned) instead of a 30-day slide; `HistoryRange.isCalendar` flag; `load()` special-
  cases the bounds; the History segment list now shows Day / Week / Month / **Last month**.
- **Month compare analytics** (,this running month vs the previous complete month):
  `HistoryRepository.monthCompare()` reads the hour tier (weighted avg PM2.5 + per-stage
  seconds + recorded-hour buckets) and returns `MonthStats? previous/current`; the
  `MonthCompare` card on the Last-month view shows Average PM2.5 / Dirty air / Clean air /
  Recorded hours per column + a CLEANER/WORSE summary line. Provider `monthCompareProvider`
  (recomputed with the history epoch). Verified by tests with the deterministic 2-month seed
  (both calendar months populated: prev Oct 8-31, current Nov 1-5).
- **History metrics: Fan + Battery graphs retired** (D-032 display filter): the dropdown now
  carries PM2.5 / PM10 / PM1.0 / Temperature / Humidity / VOC. DB columns and seeding remain —
  a display change only (locked by a test).

Test pins: last-month bucket load (≥ 20 seeded day-hours), monthCompare split assertions
(prev/current non-null, dirty totals, avg PM > 40 — the dirty story), the compare card
widget (segment tap → 'Month compare' + rows + 'last month' summary), and the metric-set
retirement. COVERAGE note: hour tier coverage uses sample_count × bucketMs — unchanged.

## Task 12 (started, NOT implemented — next agent's list): user-centric UI sweep

Requirement set (user, 2026-11-07): make the app human-friendly; sweep non-technical labels;
add Health Recommendations to the Air tab; simplify the device picker; remove dev-ish labels.

Read the code, planned edits (call sites + affected tests recorded):

1. **Device picker** (`lib/features/device/device_picker.dart` L151-155): replace the row
   subtitle `'service §D-002 · ${r.rssi} dBm'` with just the advertised name + a signal
   indicator: `Icons.signal_cellular_alt_[1|2|3]_bar — 20-px trailing icon`, thresholds
   ≥ −60 → 3-bar, ≥ −75 → 2-bar, else 1-bar (rssi null → 1-bar). No subtitle at all.
2. **System tab** (`lib/features/dashboard/dashboard_page.dart` L136-172):
   VOC row — label `'VOC (GAS kΩ)'` → `'Air chemicals (VOC)'`; subtitle technical texts →
   user text ('Chemical vapors elevated — air level counts worse' / 'Chemical vapor gauge').
   FAN row — delete the `'commanded target (v3)'` subtitle. BATTERY row — remove
   `Fmt.volts(...)` from the subtitle list (keep 'Charging' only when charging).
3. **Device tab** (`lib/features/device/device_page.dart`): DELETE the 'Real transport
   (flutter_blue_plus)…' banner card; info card rows — 'Protocol' + 'Time sync' rows removed
   (dev-speak); filter-counters card sublabels humanized ('RPM·µg·s integral' →
   'weighted particle-and-fan index', '§4.4 "st"' refs → 'per device air level', '(NVS)' from
   the persistence line, '@ 4000 RPM' from the fan-hours sub).
4. **Air tab** (`dashboard_page.dart` _body): ADD a Recommendations card under the PM tiles —
   stage-driven plain-language advice (stage 1 keep routine; 2 keep it running; 3 full fan +
   close windows; 4 max fan + seals/avoid cooking smog; 5 limit exposure/leave), hidden when
   the stage is unavailable; replace the X6 invalid-stage dev text with a user line.
5. **History page**: coverage caption suffix = 'gaps = no data' phrasing.
6. **Tests to touch when applying:** pages_test system assertions (drop
   `Fmt.volts`, the emulator-banner find — repoint to 'Connected to DOCASA-AirPurifier'),
   history 'Coverage:' assertions still substring-match, X-dev texts unaffected. grep
   `commanded\|dBm\|emulator\|RPM·µg·s` post-edit for leftovers.

PENDING final verification with the user (phone screen asleep): the Last-month view +
compare card on-device (Demo artifact, freshly installed at
`releases/docasa-demo-20261107.apk` — the seeded 2-month story remains in its DB).

## Task 13 (2026-11-07): user-centric UI sweep implemented + verified (D-033)

Implemented per the Task-12 handoff plan, verified live on the Demo build on the phone:
1. **Device picker row**: title = advertised name only, trailing = a cellular-bar icon
   (≥ −60 full bars, ≥ −75 two, else one) — dBm +	service §D-002 subtitle removed.
2. **System tab**: 'Air chemicals (VOC)' + 'Rough gauge of chemical-vapor level'
   ('Chemical vapors high — air level counts worse' when < 30 kΩ, keeping the v3 bump
   semantics); FAN SPEED has no sub-label (commanded-target text retired); BATTERY drops the
   voltage figure (only 'Charging' when charging).
3. **Device tab**: the 'Real transport/flutter_blue_plus' banner card deleted; info card
   rows → Maker / Model / Firmware / Hardware (Protocol + Time-sync rows removed); counter
   card → 'Device counters' with friendly subs (equivalent full-speed hours /
   weighted particle-and-fan index / lifetime since first power-on).
4. **History**: coverage caption = 'gaps mean no recorded data'.
5. **Filter page**: subs ('equivalent full-speed hours', 'weighted particle-and-fan index',
   'hours in POOR/BAD/HAZARD air since the filter swap', 'seconds per air level the
   purifier measured', 'lifetime since first power-on'), counters title de-"raw"ded.
6. **Air tab recommendations** — stage-driven plain-language card per the AQI guidance the
   user provided (Good..Hazardous condensed to 2 bullets each: what it means + what to do):
   verified GOOD ('Air is clean — no health concerns…'); invalid-stage card humanized.

Gates: analyze 0 issues; 78/78 tests (system-test now asserts volts/commanded are GONE;
device test repointed to the connection card). Artifacts rebuilt + installed:
releases/docasa-demo-20261107.apk + docasa-ble-test-20261107.apk.
Bench/visuals: picker bar-icon render requires advertising devices (screenshot skipped —
no purifier powered at capture time); row code verified via the sweep + tests.


## Task 14 (2026-11-07): mock device picker in the non-BLE flow (D-033 companion)

User request: verify the device-picker visuals without the prototype — tapping 'Connect'
on the Demo non-BLE build should show the same device-selection modal with a mock device.

- `startConnectFlow`: the `!realBle` branch now routes through
  `showMockDevicePicker()` — the same bottom-sheet visual (title, mock
  "DOCASA-AirPurifier" row with the cellular-bar icon, Cancel) — and picking the row
  connects the built-in emulator (previous behavior: silent direct connect, no picker).
- `showMockDevicePicker` returns false on cancel/outside-tap (null-coalesced).
- Widget test added (`device_picker_demo_test.dart`): the sheet lists the mock row +
  signal icon, Cancel button, and returns true on pick.
- Verified live on the Demo build: Reconnect → sheet → picking the row → CONNECTED
  (Device page valid). Screenshots in tmp (demo-picker2/demo-picked).
- Note: the RecordingService boot-time auto-connect keeps connecting the emulator
  directly at cold start (pre-seed/pre-pick behavior unchanged — the picker engages on
  user-initiated Connect/Reconnect actions).

---

## WRAP-UP (2026-11-07, end of session) — handoff snapshot

- **Ship state:** all requested features live through `759fef3`; sessions Tasks 1–14 are the
  evidence trail (each: procedure → findings → fix → live verification).
- **Gates at wrap:** app analyzer 0 issues / 79/79 tests; firmware v4.2.1 compile 738,567 B
  flash 56% / 44,828 B RAM 13% / 0 warnings, §10.2 diff gate PASS (active sketch v5).
- **Artifacts (local, releases/):** `docasa-ble-test-20261107.apk` (installed on the A34;
  connects to the flashed v4.2.1 purifier) and `docasa-demo-20261107.apk` (no-hardware
  path: emulated device, mock device-picker flow, 2-month dirty seeding + dev options;
  verified: seed → 1%-health modal; picker flow → connect).
- **Two parallel-install apps on the phone:** DOCASA BLE Test (com.example.docasa_app.ble)
  and DOCASA Demo (com.example.docasa_app.demo) — fresh installs required uninstalls after
  host-signing-key changes (see Tasks 10/14).
- **Next worker queue (per Development-Process §11 'Next (in order)'):** G1/G2 formalities;
  G4 remainder; cartridge numbers; inventory.yaml secret rotation.
- **Known cosmetic debt:** fake transport Device info fw string ('4.1.0'); the demo
  mock-picker sheet is static (no scan animation); demo history shows seeded story until
  seeded again after a wipe.


## Task 15 (2026-11-08): device counters → Device tab (dev-gated); Air recommendations → bottom

User request: get the raw counters off the Filter tab (they belong in dev-land), keep them
reachable under the Device tab only when developer mode is enabled, and move the Air-tab
Recommendations card to the bottom of the page (after the three PM sections).

1. **Filter tab** (`filter_page.dart`): `_countersCard` + `_row` deleted — the page keeps the
   connect prompt, health hero, basis toggle + sensitivity, reset placeholder, explainer cards.
   `core/format.dart` import dropped (no remaining Fmt use).
2. **Device tab** (`device_page.dart`): the counters card is now `counters != null && devOptions`
   and absorbed the moved rows: Dirty-air time (0.x h), Time share per stage (both require
   `stageSeconds.length >= 5`, from the old Filter card), plus the 'Counters live on the
   purifier…' caption and the existing Refresh button.
3. **Air tab** (`dashboard_page.dart`): `_recommendations(stage)` moved to the last child of the
   ListView — after StageHero (PM2.5), PM1.0 and PM10 tiles (and after the invalid-stage notice).

Gates: analyze 0 issues; **80/80 tests** — `filter_basis_test` gained a Device-tab test
(7-tap dev unlock → moved rows visible with the fixture's 0.3 h dirty read; also asserts
absence before the unlock), the Filter-tab test asserts the default basis line and that raw
counters are gone; `pages_test` filter test dropped the two raw-row assertions (moved).

Live on the A34 (demo build, fresh install data → dev options OFF): Device tab shows
connection + Device information only (gating proof); 7 quick taps on the info card reveal
Developer options + the full Device counters card with all moved rows; Filter tab shows no
counter card; Air tab shows Recommendations at the bottom under the PM tiles.
Note: counters read 0 at fresh boot (fake emulator runtime starts clean — demo operator
re-seeds via 'Seed demo data (2 months)' before a panel).

## Task 16 (2026-11-08): layout fix — Time-share-per-stage row in Device counters

User-reported bug: with long values the 'Time share per stage' KEY label printed vertically
(one character per line) in the Device counters card. Root cause: in the `_kv` Row the
right value column is a non-flex child measured against UNBOUNDED width — the joined
single-line value ('3600000s · 28800s · …') is as wide as its longest line, starving the
Expanded label of width.

Fix (device_page.dart): the value now prints ONE LINE PER AIR LEVEL — 'GOOD 201180s /
FAIR 139127s / POOR 600900s / BAD 1955100s / HAZARD 991740s' (stage names from
AirStage, GOOD→HAZARD order) via a small `_kvLines` helper whose right column is
`Flexible` so long notes wrap instead of stealing label width.

Gates: analyze 0; 80/80 (the Device-tab test now also asserts the per-line format with the
wide fixture: 'GOOD 3600000s' + 'HAZARD 0s'). Verified live on the A34 after re-seeding
(985.5 h dirty): label horizontal, five right-aligned stage lines, no wrap; artifact pair
rebuilt + reinstalled. Note: seeding re-arms the replacement modal (story evaluated at
0..1.5% — pop expected on each evaluation until acked; D-021 cap was reset by the seed).

## Task 17 (2026-11-08): reconnect is a filter-alert trigger (D-035)

User report: in the Demo build, reconnecting did not re-present the replacement modal.
Root cause: the reconnect evaluation DID run (RecordingService listens to every
'connected' event → `_onConnected` → `_evaluateAlerts`), but the presentation was gated by
the D-021 daily cap re-alert interval (24 h since `lastAlertMs`) — a re-present was
impossible within that window. Same shared path as the BLE build, so both behaved the same.

Fix (`notifications.dart` + `recording_service.dart`, shared by both transports):
- `FilterAlertDecision.shouldNotify` gains `freshConnect` — when the evaluation was
  triggered by a connect/reconnect handshake, the cap is bypassed (degraded health is
  re-surfaced at attach time; the health gate and the connected gate still apply).
- `_onConnected` passes `freshConnect: true`; the 5-minute timer and `evaluateNow()`
  (sensitivity-change / seed-path) evaluations stay capped. `lastAlertMs` still stamps at
  every presentation, so background ticks remain at-most-daily.
- kDebugMode-gated `[filter-alert]` debug trail prints each evaluation's inputs + decision
  (0 in release builds — checked).

Gates: analyze 0; **82/82 tests**. New `test/data/alert_reconnect_test.dart` verifies
service-level wiring with a connect-emitting fake: (1) a fresh connect presents degraded
health despite a 298-ms-old cap stamp (bypass works), (2) a routine `evaluateNow` at the
same age stays suppressed (cap intact for non-connect triggers). The alerts-port capture
presents exactly once in each scenario (degraded fixture ST-2..4 ≈ 98 % of budget).

Device evidence (A34, demo build): the seeded story promotes the modal from the seed
button itself ('Seeded 2 months — 985 h dirty air; device counters adopted' + 'Filter
health is at 2 %' modal at 11:11 — presentation chain proven live). The touch-driven
A/B on the reconnect button could not be completed on-device: the Device-tab list
re-anchors under its 1 Hz counter re-render, so scripted taps drift — the app-side causal
chain (connect event → evaluation → bypass → modal) is machine-verified instead; the
release build carries the same shared logic as the BLE app and the purifier.
Bench note: buttons at (760,1382)-ish move between screenshot and touch — when re-driving
the phone, anchor + tap must happen within ~1 s of the same layout.

## Task 18 (2026-11-08): presenter-oriented User Manual shipped

Deliverable: `docs/User-Manual.md` — a comprehensive, PDF-exportable manual that doubles
as the panel presentation guide. Every UI string, threshold and behavior in it was
cross-checked against the code/decision state at tip `855e813` (labels 'Air chemicals
(VOC)', 'equivalent full-speed hours' etc.; 7-tap reveal; seed button names; alert
threshold 10 %; sensitivity multipliers ×1.5/×1.0/×0.5; history ranges Day/Week/Month/
Last month with the month-compare card; PM/Temperature/Humidity/VOC metric list with
Fan/Battery retired per D-032).

Contents: what the product is; the five tabs (per-element meaning + presenter tips);
connection states + auto-connect/reconnect/picker; time sync; developer tools (incl.
the never-erase-NVS rule); the filter-replacement alert incl. the D-035 reconnect
behavior; persistence map (device NVS vs phone DB vs emulator runtime); theme; the
3-minute demo playbook with pitfalls (app restart resets the fake counters — re-seed;
don't press 'I just replaced the filter' mid-demo); troubleshooting quick list;
glossary; reference docs + a pandoc PDF-export command (no pandoc on this host — the
doc's export line is the instruction); §11 'Planned changes' records the two agreed,
deferred Filter-tab revisions verbatim (basis → dev-only default; manual reset with a
confirmation prompt).

No app code changed; gates not re-run (doc-only). Development-Process §11 refreshed:
next task = the Filter-tab refinement batch, then the standing formalities queue.
