# DOCASA — Decision Log (ADR-lite)

Append-only. Each entry: context → decision → consequences. Entries supersede
`IoT-Integration-Plan.md` (Plan v1) sections where cited. Format: status · date · phase affected.

---

- **D-001 — ESP32 module is WROOM** · resolved · 2026-10-30 · firmware
  Context: Plan OQ #1 / §7.4 flagged GPIO16/17 (PMS7003 UART2) as PSRAM-conflicting on WROVER.
  Decision: user confirmed the module is **ESP32 WROOM**.
  Consequences: §7.4 blocker cleared; UART2 stays on 16/17; no pin reassignment task.

- **D-002 — BLE UUIDs frozen** · resolved · 2026-10-30 · firmware + app
  Context: Plan §3.2 UUIDs were placeholders requiring regeneration before implementation.
  Decision: fresh v4 UUIDs generated (prefix `d0ca5a`) and frozen in
  `BLE-Protocol-Contract.md` §2, incl. two reserved spares.
  Consequences: firmware and app hard-code the same constants; regeneration now forbidden
  without a new decision entry.

- **D-003 — JSON v1 encoded with ArduinoJson 7.x** · resolved · 2026-10-30 · firmware
  Context: Plan §12.2 library list omitted a JSON library although §3.4 mandates JSON payloads.
  Decision: add **ArduinoJson 7.x** alongside **NimBLE-Arduino 2.x**; exact versions pinned in
  the Decision-Log when installed at Phase 1 (partial resolve of Plan OQ #5).

- **D-004 — NVS counter design** · resolved · 2026-10-30 · firmware + app
  Context: Plan §4.2 gaps — (a) `fanSeconds` as uint32 overflows (~12 days at max speed:
  3000 h × 4000 RPM × 3600 s ≈ 4.3 × 10¹⁰ > 2³²); (b) `runtimeHours` and `powerOnHours` defined
  identically (Plan itself noted "may merge").
  Decision: both integrals uint64 end-to-end (`fanSec` RPM·s, `pwfs` RPM·µg·s; RAM + NVS via
  `putULong64`); merge lifecycle counters into a single `onSec` (u32 seconds, exposed as whole
  hours `on`); drop the `rt` payload key.
  Consequences: supersedes Plan §4.2 table and the `on`/`rt` row of §3.4; Contract §4.4 updated;
  app must use 64-bit ints (Dart native OK, web not a target — risk 7.20).

- **D-005 — Working firmware = `docasa-air-purifier-v4`** · resolved · 2026-10-30 · process
  Context: Plan §12.2 sanctions moving the v3 `.ino` into its own folder; a pristine diff target
  is needed for the behavior-preservation gate.
  Decision: keep `firmware/baseline/docasa-air-purifier-v3.ino` pristine forever; active sketch is
  `firmware/docasa-air-purifier-v4/docasa-air-purifier-v4.ino`, seeded as a byte-identical copy.
  `FIRMWARE_VERSION` scheme `MAJOR.MINOR.PATCH`: 4.0.0 = after Phase 1 (NVS), 4.1.0 = after
  Phase 2 (BLE).
  Consequences: all firmware changes are additive edits to v4, diffed against baseline
  (Development-Process §10.2).

- **D-006 — Android-first app target** · resolved · 2026-10-30 · app
  Context: user toolchain is Android Studio; Plan §6.2 also covers iOS hurdles.
  Decision: Android first; iOS deferred (foreground-first caveats in Plan §6.2 still apply if
  ever targeted).
  Consequences: iOS-specific work is out of all current phase estimates.

- **D-007 — App state management** · pending (decide at Phase 3 kickoff) · app
  Recommendation: **Riverpod 2.x** (first-listed in Plan §6.1 layering; testable without
  hardware, DI-friendly for the fake BLE layer).

- **D-008 — App local database** · pending (decide at Phase 3 kickoff) · app
  Recommendation: **Drift** (SQLite — Plan §6.1's suggestion; typed queries suit the
  downsampling/aggregation pipeline).

- **D-009 — Android `minSdk`** · pending (decide at Phase 4 kickoff) · app
  Recommendation: **31** (Android 12+) — avoids the legacy location-permission BLE-scan path
  (Plan §6.2). Trade-off: excludes Android ≤ 11 devices. Revisit before any public release.

- **D-010 — Security of write commands vs §1.4 freeze** · pending (decide at Phase 5 kickoff) · firmware
  Context: Plan §7.8 proposes passkey-on-TFT, but drawing on the TFT is display-code change,
  which §1.4 freezes (conflict recorded as finding R3).
  Options: (a) rule passkey display in-scope as BLE-adjacent; (b) ship unauthenticated writes
  with app-side confirmation UX (Plan §7.8 accepts this for MVP); (c) app-held PIN check.
  Interim: dev builds are unauthenticated (Plan §7.8 MVP flag).

- **D-011 — Filter budgets & preset filter models** · pending (user input needed by Phase 4) · app
  Context: Plan OQ #4 — `loadBudget`/`hourBudget` are app-side config (Plan §4.2).
  Recommendation: ship configurable defaults (e.g. ~3000 h nominal equivalent) + settings UI;
  replace with real values once the actual filter model is chosen.

- **D-012 — App history retention policy** · pending (design task within Phase 3) · app
  Context: risk 7.21 — 1 Hz recording is ~86 k samples/day; unbounded growth.
  Recommendation to evaluate: raw 1 Hz kept 24–48 h → 1-min aggregates 7 d → 1-h aggregates 90 d;
  decided and recorded when the DB layer is built.

- **D-013 — Toolchain pins (Phase 0)** · resolved · 2026-10-30 · firmware + app
  Context: Plan OQ #5 — verify core + library compatibility in the actual toolchain.
  Decision: arduino-cli **1.5.1**; ESP32 Arduino core **3.3.12** (`esp32:esp32`); FastLED **3.10.8**;
  Adafruit ST7735/ST7789 **1.12.0**; Adafruit GFX **1.13.0** (+BusIO 1.17.4); Adafruit Unified
  Sensor **1.1.15**; Adafruit BME680 **2.0.6**; Adafruit PM25 AQI Sensor **2.0.0**; Flutter
  **3.47.9** / Dart **3.13.7**. Baseline compile of v4 (byte-identical to v3): clean, 0 warnings,
  397,315 B flash (30 %), 26,676 B RAM (8 %) — G0 report.
  Notes: core 3.x FQBN is `esp32:esp32:esp32` (`esp32dev` alias removed); FastLED 3.10.8 accepts
  `FASTLED_ESP32_I2S` silently — LED behavior to be visually confirmed at G1/G2, pin older
  FastLED if it deviates; NimBLE-Arduino 2.x + ArduinoJson 7.x pinned when installed (Phase 1/2).
  Partially resolves Plan OQ #5 (NimBLE-vs-core check remains at Phase 2).

- **D-014 — NimBLE-Arduino 2.5.2 + ArduinoJson 7.4.3 pinned** · resolved · 2026-10-30 · firmware
  Context: D-003 promised exact pins at Phase 1/2; Plan OQ #5.
  Decision: **NimBLE-Arduino 2.5.2** + **ArduinoJson 7.4.3** installed and compile-verified with
  core 3.3.12 (v4.1: 732,643 B flash / 55 %, 40,572 B RAM / 12 %, 0 warnings).
  Notes: API drift found vs. the 1.x-style calls — NimBLE 2.5.2 has **no
  `getSubscribedCount()`**; CCCD gating is implemented via the `onSubscribe` callback
  (subValue bit 0) maintaining per-characteristic flags, reset on disconnect. Runtime
  compatibility confirmed only at G2 (bench). Supersedes the "pin later" clause of D-003.

- **D-015 — Phases 1+2 merged; bench gates deferred** · resolved · 2026-10-30 · process + firmware
  Context: user timeline pressure; hardware not yet available for bench/flash.
  Decision: (a) Phases 1 and 2 executed as a **single firmware session** (user-approved) —
  `FIRMWARE_VERSION = 4.1.0` covers both (the interim 4.0.0 NVS-only step from D-005 is never
  shipped). (b) v4.1 is **code-complete and compile-verified**; gates **G1/G2 run later from
  `docs/Bench-Runbook.md`** when hardware arrives — they remain the definition of done for
  Plan P0+P1. (c) The Command characteristic handles `{"cmd":"time"}` now (Phase 4 handshake
  dependency; trivially in scope) and deliberately **ignores** `resetFilter` until Phase 5.
  (d) Behavior-preservation gate: `tools/firmware-diff-check.sh` PASS — 312 lines added,
  0 removed/changed vs frozen v3 baseline (setup()/loop() contain only the two pre-approved
  insertion calls plus top-of-file includes).

---

- **D-016 — Phase 3 dependency pins (Oct 2026 registry state)** · resolved · 2026-10-30 · app
  Context: D-007/D-008/D-012 deferred exact pins to Phase 3; the registry moved past the
  versions the Process doc anticipated.
  Decision: pinned — flutter_riverpod **3.4.3** (resolves **D-007**; Riverpod 3.x, not the 2.x
  the Process anticipated: async `.value` is nullable, `valueOrNull` removed, `Notifier` API,
  `StateNotifierProvider` only via `legacy.dart`); drift **2.35.3** + drift_dev **2.35.2** +
  build_runner **2.17.1** (resolves **D-008**; note: non-autoincrement PK columns arrive in
  `Companion.insert` as optional `Value<T>` fields — wrap PK values in `Value()`);
  **`sqlite3_flutter_libs` removed** (its 0.6.0+eol release is a no-op EOL stub; `sqlite3` 3.5.2
  bundles the native loader via Dart build hooks); flutter_blue_plus **2.3.14** (pre-pinned for
  Phase 4); fl_chart **1.3.0**; flutter_local_notifications **22.3.3** (v22 requires
  `initialize({required settings:})` / `show({notificationDetails:})` named params and **core
  library desugaring** — enabled in `android/app/build.gradle.kts` with desugar_jdk_libs 2.1.4);
  intl 0.20.3; path_provider 2.1.6. Retention policy (resolves **D-012**): the recommended
  ladder as coded — raw 1 Hz kept **24 h** → 1-min aggregates **7 d** → 1-h aggregates **90 d**,
  compaction pass every 60 s while connected (`lib/data/history_compactor.dart`). minSdk
  pre-set to **26** (per D-009) in the same build-script pass; BLE manifest permissions still
  land with Phase 4.
  Notes: D-011 (real budget numbers / filter model) remains pending → Phase 4 (user input
  needed).

- **D-017 — Phase 4 pre-built without hardware (entry-gate deviation)** · resolved · 2026-10-30 · app
  Context: §7 declares G2 + G3 passed as Phase 4 entry; no hardware exists yet, and the user
  chose pre-building over blocking (G3 passed 2026-10-30).
  Decision: Phase 4 tasks 1–5 are **code-complete, analyzer+test-gated, runtime-unverified**:
  real transport `lib/ble/fbp/fbp_docasa_connection.dart` behind the unchanged
  `DocasaConnection` interface — UUID scan → connect (MTU 247) → §6.1 handshake (time sync on
  every connect) → 3-CCCD merge into complete frames → reconnect loop 0.5→8 s backoff
  (pure `backoffDelay`, tested); runtime permissions inside the transport (scan/connect +
  legacy location ≤ API 30), manifest BT + `POST_NOTIFICATIONS` added. Transport switch is a
  single `dart-define`: `--dart-define=DOCASA_REAL_BLE=true`; the emulator stays default so
  dev/tests never need hardware.
  Notes: **G1/G2 bench still must run BEFORE any G4 device test** (G4 checklist governs);
  FBLP 2.x stream semantics and merge alignment are the known-unverified surface.

- **D-018 — Phase 4 dependency + license (resolves D-011)** · resolved · 2026-10-30 · app
  Context: FBLP 2.x introduced a required `License` enum on `connect()` (dual-license:
 nonprofit vs paid commercial); D-011 wanted filter-budget numbers by Phase 4.
  Decision: **flutter_blue_plus 2.3.14 with `License.nonprofit`** (personal/civil use — paid
  commercial tier only if the app is commercialized someday); **permission_handler** added
  (the one justifiable addition — Android runtime permission UX). D-011: ship **configurable
  placeholder budgets** (`FilterBudgets` defaults ≈ 3000 h nominal-load equivalent; editable in
  settings; swap exact numbers when the real filter cartridge is chosen — bench session is the
  natural moment).

- **D-019 — G4 attempted before G1/G2 bench (planned deviation)** · resolved · 2026-10-30 · process
  Context: user wants real-BLE testing now; the ESP32 will be flashed and bench-verified
  (G1/G2) only at a later session.
  Decision: build a parallel-install G4 test artifact
  (`tools/build-ble-test-apk.sh` → `--dart-define=DOCASA_REAL_BLE=true -PrealBle=true` →
  `com.example.docasa_app.ble`, launcher label "DOCASA BLE Test") and run the §7 G4 checklist
  informally, **before** G1/G2 firmware runtime verification. If BLE behaves unexpectedly,
  distinguish firmware-side causes (unverified NimBLE paths, D-015) from app-side causes before
  changing either. G1/G2 remain required before declaring Phase 1+2 done.

- **D-020 — G4 practice round on a real phone (no hardware in range yet)** · resolved · 2026-10-31 · app
  Context: user wants real-BLE UX now; the ESP32 remains unpowered/unflashed (D-019 path).
  Decision (all on-commit, analyzer + 52 tests green, released in the BLE-test artifact):
  (a) **Connect flow = live device picker** for the real transport — bottom-sheet scan in
  15 s windows listing only devices whose advertisement carries the Contract §1/§2 service
  UUID (or the exact `DOCASA-AirPurifier` name), tappable by name with RSSI; when nothing
  valid shows, a diagnostic listing of raw nearby advertisers renders NON-tappable (user
  requirement to narrow the list); tapped device is passed to `FbpDocasaConnection.connectTo()`
  (interface unchanged, emulator untouched). Boot-time auto-connect holds until first pick,
  then reconnect-drop loops target the picked device with the 0.5→8 s backoff.
  (b) **Handshake device verification** (Contract §3): after GATT discovery the app requires
  mfg `DOCASA`, model `DOCASA Air Purifier`, fw `4.x` — exact strings verified in the v4.1.0
  source (2A29/2A24/2A26) — else disconnect + logged verification failure.
  (c) **Permission-gate fix**: `locationWhenInUse` removed from `_ensurePermissions`
  (neverForLocation scan on API 31+ never needs it; the permanent-`denied` result froze the
  loop pre-scan — reproduced on the A34 via the instrumented trail).
  (d) **Instrumentation kept for G4 triage**: `debugPrint` decision trail in the transport
  (state changes, permission results, link failures, scan summaries, first frame). The
  diagnostic scan is currently **unfiltered** with per-cycle name+UUID logging;
  `shortcut: unfiltered scan costs one log line per 12 s cycle, restore
  `withServices` filtering after G4 passes`.
  (e) **Artifact tooling**: `tools/build-demo-apk.sh` and `tools/build-ble-test-apk.sh`
  (Gradle `-P-demoBuild`/`-PrealBle` + dart-define) — parallel-install `DOCASA Demo` /
  `DOCASA BLE Test` (id suffixes `.demo`/`.ble`, labels distinct); launchable-activity stays
  `com.example.docasa_app.MainActivity` for all variants (aapt-verified after an
  `am start -n *.ble/.MainActivity` type-3 error from the suffix shorthand).
  Observed so far on the A34: BT permissions granted, scan cycles run correctly, **zero
  DOCASA advertisements seen** — purifier never powered in range; nothing app-side failed.

- **D-021 — Filter-replacement alert flow (supersedes the Phase-5 gate on `resetFilter` UX)** · resolved · 2026-11-01 · app (+ firmware follow-up)
  Context: Phase 5 security ruling (D-010) held `resetFilter` UI-gated forever; the user now
  specifies the replacement flow in full (modal + push + daily reminder + counter reset).
  Decision (all analyzer/54-test green, commit `92cba76`):
  (a) Main channel = **in-app modal** — raised on connect-time or evaluation-time detection
  of health ≤ threshold while the app is visible; options: "I'll replace it at a later
  time" (records `filter.alertAckMs`, reminder capped at one per day via the existing
  `lastAlertMs` presentation stamp) and "I just replaced the filter" (calls
  `DocasaConnection.resetFilter()`, invalidates counter/health providers, re-arms the daily
  cap by zeroing `lastAlertMs`).
  (b) App unfocused → **system push**; tapping it while the process is alive replays the
  modal; a cold start replays via `getNotificationAppLaunchDetails` payload check.
  (c) Demo build only: "Preview filter alert" button raises the modal on demand;
  prod build hides it (`kRealBle`).
  (d) **Firmware follow-up (next maintainer flash)**: v4.1.0 still IGNORES `resetFilter`
  (the write-chars handler no-ops it) — until the firmware accepts the command, the
  "replaced" option in the prod build resets app-side provider state but the device
  integrals keep accumulating; the commander write path is already exercised end-to-end.
  Expected: accept the command with counter-zeroing, diff-gate PASS, bump
  FIRMWARE_VERSION 4.1.1, close Phase 5 item.

- **D-022 — Firmware v4.1.1 accepts `resetFilter` (closes D-021d)** · resolved · 2026-11-01 · firmware
  Context: D-021's replacement flow reached into the Phase-5 gate (D-010) — the user ordered
  the "I just replaced the filter" reset path.
  Decision: v4.1.1 — the command handler now implements Contract §5 line 110 exactly:
  `{"cmd":"resetFilter"}` zeroes `fanSec` + `pwfs`, **persists immediately** (a cut right
  after replacement cannot resurrect counters from the 5-min throttle window), keeps
  `onSec`. `DOCASA_FW_VERSION = "4.1.1"`. Compile clean (732,819 B flash 55%, 40,572 B RAM
  12%, 0 warnings); `tools/firmware-diff-check.sh` PASS — additions only (Plan §1.4).
  App side (unchanged since `92cba76`): after `resetFilter()` it invalidates the counter /
  health providers → re-read per Contract line 110 ("app MUST re-read and confirm zeros");
  the confirmation surface is the Filter page figures + next alert cycle.
  Notes: the maintainer's flash instructions (`firmware/README.md`) still apply — sketch now
  reports 4.1.1 on boot; nRF Connect/Serial corroboration point: write `{"cmd":"resetFilter"}`
  → Serial logs "usage integrals zeroed", counters read back 0, `on` unchanged.

- **D-023 — Branding assets + dark/light theme toggle** · resolved · 2026-11-01 · app
  Context: user supplied banner artwork and requested the header redo.
  Decision: header = user-supplied PNG banner top-left (tight-cropped transparent variants
  `assets/docasa-logo-banner-dark-t.png` / `-light-t.png`, nav-asset-registered, chosen by
  theme brightness) + a moon/sun-icon Switch top-right toggling dark (house default,
  persisted `ui.themeMode` in the KV table, no migration) and a new `DocasaTheme.light()`
  (same cyan seed). SafeArea retained per earlier notification-bar fix.
  Notes: original square-crop assets removed; demo + BLE-test exports rebuilt with the
  new branding (releases 2026-11-01 evening builds). Windows-Arduino toolchain blockers for
  the maintainer (FastLED `objs.a` linker issue, OneDrive sketchbook/cache) are documented
  in `firmware/README.md` § Windows troubleshooting.

- **D-024 — Development host re-provisioned on Windows 11 (D-013/D-014 pins preserved)** ·
  resolved · 2026-11-05 · process
  Context: prior host retired; the new Windows 11 24H2 machine had none of the project
  tooling on PATH (no flutter/dart/adb/arduino-cli). Environment is a live dependency of
  every gate ritual, so the replacement is recorded rather than assumed.
  Decision: full CLI re-provision, pins unchanged — Flutter 3.47.9/Dart 3.13.7 at
  `~/development/flutter` (SHA-256-verified zip); Android SDK at `~/Android/Sdk`
  (platform-tools, platforms;android-37.0, build-tools 37.0.0 + AGP-pulled 36.0.0, NDK
  28.2.13676358, licenses accepted); arduino-cli 1.5.1 in `~/.local/bin` + esp32 core
  3.3.12 + library pins D-013/D-014 (NimBLE-Arduino 2.5.2 **git-sourced at tag `2.5.2` —
  absent from the Library-Manager index, needs `library.enable_unsafe_install: true`**;
  ArduinoJson 7.4.3, FastLED 3.10.9, Adafruit ST7789/GFX/BusIO/BME680/UnifiedSensor/
  PM25AQI); graphify 0.9.102 (uv tool, already present); `sqlite3.dll` in `~/.local/bin`
  for Drift tests. Java unchanged (Adoptium JDK 21). Windows-only constraints adopted:
  **Developer Mode ON** (flutter plugin symlinks), `platforms/android-37` ← junction to
  `android-37.0` (AGP 9.1 desugar task requires the literal hash; warning is harmless),
  user env ANDROID_HOME/JAVA_HOME/PATH set outside the repo.
  Notes: verified live on 2026-11-05 — `flutter doctor` green (Android toolchain 37.0.0),
  `flutter analyze` 0 issues, `flutter test` 54/54, firmware v4.1.1 compile
  733,019 B flash 55% / 40,444 B RAM 12% (0 warnings), `tools/firmware-diff-check.sh`
  PASS, BLE-test artifact `releases/docasa-ble-test-20261105.apk` built, installed and
  launched on the re-authorized Samsung A34 (device picker + FBP D-020 trail; G4 runtime
  gate unchanged). No source changes: the plugin-registrant "modifications" from `pub get`
  were EOL-only churn and reverted. Setup flows for the maintainer: `docs/App-ADB-Test.md`
  and `firmware/README.md` unchanged in content.

- **D-025 — BLE connect-hang root cause: short-form DIS UUID string comparison (logcat probe)** ·
  resolved · 2026-11-05 · app
  Context: §11 next-step (1) closure — app picker lists `DOCASA-AirPurifier` but selecting it
  left CONNECTING + center spinner forever. Ran the playbook's logcat layer live on a fresh
  rebuild of the BLE-test artifact (Samsung A34, re-authorized): link stage fully healthy
  (connect → MTU 247 GATT_SUCCESS → `discoverServices` **5 services GATT_SUCCESS**) then
  `FBP: link failed: Bad state: No element` at `readDeviceInfo.read` — `c.uuid.str128 == uuid`
  compared the full 128-bit runtime UUID against the Contract's short-form `'2A29'…` constants
  (never equal); the custom telemetry constants are full-form, which is why the
  picker worked. Never reached before because earlier practice rounds saw zero DOCASA ads (no
  hardware in range). Firmware exonerated (DIS values verified over the air post-fix).
  Decision: one-line fix — `readDeviceInfo` characteristic lookup compares via
  `c.uuid == Guid(uuid)` (Guid `==` normalizes short-form to the full 128-bit lowercase form;
  a genuinely missing characteristic still throws the same `StateError` → backoff). Analyzer
  0 issues, 54/54 tests, BLE-test artifact rebuilt + reinstalled, verified live: pick →
  connected in ~1.4 s, `handshake device info: mfg=DOCASA model=DOCASA Air Purifier fw=4.1.1`,
  CCCDs subscribed, first complete frame decoded, dashboard streaming real PM values.
  Notes: G4 checklist remainder (walk-away backoff, restart persistence, push) and G1/G2
  formalities still owed; debugPrint trail stays until after G4 (D-020d).

- **D-026 — History chart theming made theme-derived (light-mode tooltip + axis invisible)** ·
  resolved · 2026-11-05 · app
  Context: light mode left the History line chart dark-styled — axis labels (`Colors.white54`
  hard-coded) invisible and the touch tooltip unreadable. Root cause in fl_chart 1.3.0 defaults:
  the chart never configured `LineTouchData`, and the default tooltip assigns the text the
  LINE color (`cs.primary` — pale in the light scheme) on a hard-coded `blueGrey.darken(15)`
  bubble.
  Decision: theme-derive both — `_axisStyle` uses `Theme.of(context).colorScheme.onSurfaceVariant`;
  explicit `LineTouchTooltipData` with bubble `cs.primaryContainer` and item text
  `cs.onPrimaryContainer` (bold 14; raw `toString` parity with the previous default items).
  Verified on the A34 in BOTH themes (hold-press capture; fast tap clears the tooltip on
  touch-up so it never shows). Analyzer 0 issues, 54/54 tests; artifact rebuilt + reinstalled.
  Notes: dark-mode bubble hue changes from neutral blueGrey to the dark-teal primaryContainer
  (house accent family) — accepted as part of the theming task.

- **D-027 — Filter-replacement basis: dirty-air hours, toggleable with a budget-multiplier scale** ·
  resolved · 2026-11-05 · app (+ firmware follow-up)
  Context: panel demo needs a simpler, explainable filter-health story than the raw µg·h load
  integral; user also wants the same human scale on the load-based method instead of free-form
  budget text fields (D-018).
  Decision:
  (a) New basis **"Dirty-air hours"** (default after install): health =
  `100 × (1 − dirtyH / (dirtyBudget × mult))`, `dirtyH = (st[2]+st[3]+st[4])/3600` s from the
  v1.1 `"st"` payload (POOR/BAD/HAZARD seconds since replacement). `dirtyBudget` placeholder
  **1000 h** (D-011-class placeholder pending real cartridge; consistent with the 3000 h
  nominal-load placeholder at typical 1/3-dirty duty).
  (b) Load-based method unchanged (`pwfs` vs `FilterBudgets`), at the same multiplier.
  (c) **Sensitivity = budget multiplier** with named steps: Relaxed 1.5× (later) · Normal 1.0×
  (default) · Sensitive 0.5× (sooner) — replaces the editable budget text-fields UI; raw budget
  constants stay code-side only. Persisted KV (`filter.basis`, `filter.mult`).
  (d) Basis toggle in the Filter tab; both methods always computable — switching is O(1) from
  retained values. Pre-4.2.0 firmware (no `"st"`) automatically falls back to load-based (X7).
  (e) `resetFilter` (Firmware v4.2.0) also zeroes + persists `st` (D-028 covers GATT additions).
  Notes: exact budget numbers still pending the real cartridge (D-011); the multiplier makes
  demo-day tuning trivial (one tap moves the ETA).

- **D-028 — Gapless offline history: envelope ring + bulk sync pulled forward to v4.2.0 (resolves risk 7.19)** ·
  resolved · 2026-11-05 · firmware + app (+ contract v1.1)
  Context: user wants 2-month gapless history incl. app-disconnect periods; Plan §5/§9 reserved
  ring-and-sync for Phase 5 with the NVS-partition blocker (7.19). A 16-B/10-min **envelope
  record** (PM min/mean/max u16 + per-stage seconds 5×u16) sizes the whole 60-day series at
  ≈138 KB — viable without any compression once a small data partition exists.
  Decision: batch into ONE firmware bump + ONE maintainer reflash:
  (a) Contract **v1.1** (ratified same day): per-stage counter key `"st"` (§4.4), `resetFilter`
  zeroing, `offlineLog` command (§5), Offline History characteristic
  `d0ca5a79-bb2b-478b-abed-9ac1441cd635` (§2/§3), record layout + drain protocol + time
  mapping (§10). UUID generated in-house pattern (d0ca5a…, v4, variant a).
  (b) Firmware **4.2.0**: custom partition CSV (`docasa_ring`, 256 KB data/0x40 — runway
  ≈ 4.6 months before overwrite; wrap detectable via `first`), NVS boot counter `boot` (1
  write/boot) + `st1..st5` (u32 s, reset with filters), window accumulators in the existing
  1 Hz tick (in-flight windows never exposed), Filter Counters payload gains `"st"`,
  `offlineLog` cursor + status/records reads, `FIRMWARE_VERSION 4.2.0`. Additive-only per
  §1.4 diff gate; §7.13 time authority unchanged (phone anchors `(bootId,slot)→wall-clock`,
  re-anchored every connect from the live stream).
  (c) App: codec golden fixtures F8/F9 + X7–X9, offline-sync drain engine at connect (§6.1
  step 8; 60 d ≈ 577 reads at MTU 247; fully-synced connect = status read only), ingestion
  into the existing 24 h/7 d/90 d ladder (Day view = 10-min envelopes; Week/Month merged up),
  exposure-share health + toggle + multiplier UI, analyzer/tests.
  (d) Filter-replacement basis decisions live in D-027 (dirty-air default, multiplier steps).
  Risks/limits recorded: wrap after ~4.6 months (re-sync gap → oldest slots rewritten; app
  treats as lost windows per §10.2), power-cut loses ≤ the in-flight window, partition change
  requires a maintainer reflash bench session (rationale: one session — both features shipped).
  (e) **Sketch lineage (user decision, recorded live):** v4 `.ino` is FROZEN at `4.1.1` and
  never overwritten again — firmware v4.2.0 goes to a **new sketch dir**
  `firmware/docasa-air-purifier-v5/docasa-air-purifier-v5.ino`, seeded byte-identical from v4,
  with `partitions.csv` beside it in the same dir. `tools/firmware-diff-check.sh` gets an
  active-sketch parameter (default: v5) so the §10.2 gate keeps proving additive-only vs the
  v3 baseline.
  Notes: contract §9 keeps only security-pairing (D-010) + later reserves.

- **D-029 — Advertised name restored to ADV payload (Contract §1 conformance)** ·
  resolved · 2026-11-05 · firmware
  Context: user report via nRF Connect + the app picker — the peripheral carries the service
  UUID but NO name ("N/A"). Root: NimBLE-Arduino 2.x does not include the GAP name in the
  advertising payload by default; the v4.1.0 BLE setup never set it explicitly, so §1's
  "Flags + complete local name" was silently unfulfilled across v4.1.x.
  Decision: additive line in `docasaBleBegin()` — `adv->setName(DOCASA_BLE_NAME);` before
  `start()` (fits the 31-byte ADV: flags 3 + name 19 + UUID in scan response per §1). Gates:
  compile 736,943 B (56%) / 44,828 B RAM (13%) / 0 warnings; diff gate PASS. Reflashed reusing
  the custom-partition upload path (NVS + ring data persisted). Verified over the air: the
  picker row now renders `DOCASA-AirPurifier` with the §D-002 subtitle.
  Notes: pickers that filter by NAME now also match (the app's §1 rule ORs name and UUID).

- **D-030 — Developer options + demo seeding chain (slider, 2-month story, device-counter dev channel)** ·
  resolved · 2026-11-05 · app (+ firmware v4.2.1, dev-channel contract addendum)
  Context: panel demonstration needs (a) the sensitivity as a 3-stop slider, (b) a seeded
  2-month mostly-dirty story that drives Sensitive → 0 % + an immediate replacement prompt,
  and (c) the seeded story mirrored into the DEVICE counters so health/alerts read from the
  device itself ("transmit the seeded data to the NVS").
  Decision:
  (a) Filter sensitivity is a **3-stop Slider** (Relaxed ×1.5 / Normal ×1.0 / Sensitive ×0.5;
    labels under the track); a sensitivity CHANGE evaluates alerts immediately (no 5-min wait).
  (b) `TwoMonthSeeder`: minute-cadence direct aggregate seeding (~57k rows) — mostly
    POOR/BAD/HAZARD minutes (85 % dirty band), device "off" overnight → REPLACES the timeline;
    returns `UsageTotals` (fs/pwfs/on/st[5]).
  (c) **Device-page Developer options**: hidden by default; the Device information card must
    be tapped 7× (2.5 s inactivity reset) to reveal the section; the section's own switch
    disables it; 'Demo data (Phase 3)' renamed 'Developer options'.
  (d) **Dev channel (firmware v4.2.1 addendum to §5)**: `{"cmd":"setUsage",fs,pwfs,"on","st"}`
    — validated u64×2/u32/array[5] — writes the usage counters into NVS+RAM (persist now).
    This is a REPLACEMENT of the device counters for the demo story; gated behind the app's
    developer options; security gate stays with v1.2 (D-010).
  (e) Seeding flow: REPLACES app history (fresh aggregates + the SAME story counters pushed
    via the connected transport — FBLP over BLE; the fake echoes for the emulator build) +
    resets the D-021 daily-cap stamps (lastAlertMs/filterAlertAckMs = 0) so the replacement
    prompt re-arms on every seeded demo; 'Seed demo data (2 months)' appears only in
    Developer options.
  Verified live on the A34 + flashed v4.2.1: seed → SnackBar "960 h dirty air", Filter page
  reads seeded `st[2..4]` = 268,980/2,317,920/869,100 s from the device; slider → Normal =
  **4 %** + immediate alert modal; Sensitive = **0 %** + the earlier immediate modal; the
  Device information 7-tap reveals the section (screenshots in the session doc).
  Gates: analyzer 0 issues, **74/74 tests** (+3: seeding ranges/projection, fake-transport
  echo, 7-tap tracker); firmware compile 738,567 B (56 %) / 0 warnings; diff gate PASS.

- **D-031 — Demo story tuned: realistic GOOD/FAIR stretches, Normal still lands near 0 %** ·
  resolved · 2026-11-07 · app
  Context: user feedback — the all-dirty 2-month skew was too blunt ("more realistic filter
  life data"); GOOD/FAIR hours exist in the story, but the demonstration must still land near
  0 % on NORMAL (default basis) and fire the replacement alert.
  Decision: `TwoMonthSeeder` retune — the purifier sleeps only ~6 h (off 00:30–06:30 → ~1080
  powered hours over the window), hour-of-day bias (07–09 & 21–22 calmer, 12–18 smoggy), and
  minute bands GOOD 2 % / FAIR 6 % / POOR 15 % / BAD 52 % / HAZARD 25 %. Deterministic result:
  Normal ≈ **1.51 %** (well under the 10 % alert threshold → the prompt fires on the DEFAULT
  configuration); Sensitive still 0 %. Tests assert the Normal band (0,10) + dirty dominance
  + counter consistency; all else unchanged.
  Gates: analyzer 0, 74/74 tests; artifact re-stamped `releases/docasa-ble-test-20261107.apk`.

- **D-033 — User-centric UI sweep (labels, picker, recommendations)** · resolved · 2026-11-07 · app
  Context: user requirement — the app must read for someone without technical knowledge:
  remove dBm/dev-jargon wording, drop the transport banner, and give stage-appropriate
  health recommendations on the Air tab.
  Decision: device-picker rows show only the advertised name + a cellular-bar icon
  (≥ −60 full, ≥ −75 mid, else weak); System tab — 'Air chemicals (VOC)' with a plain
  sub-label ('Chemical vapors high — air level counts worse' below the 30 kΩ bump),
  'commanded target' and the battery voltage figure removed (charging note kept); Device
  tab — the transport banner removed, info rows Maker/Model/Firmware/Hardware, counter
  subs humanized; Filter/History sub-labels + captions cleaned ('gaps mean no recorded
  data'; NVS/§-tags dropped); Air tab gains a Recommendations card driven by the current
  stage, two plain-language bullets each (what it means + what to do) based on the AQI
  health wording the user supplied; the invalid-stage dev text is user-readable.
  Verified on the A34 via the Demo build (picker-bar render needs no purifier — icon-only,
  code-verified via tests). Analyzer 0 issues; 78/78 tests (volts/commanded asserted gone;
  device test repointed to the connection card).

- **D-034 — Raw device counters relocated (+ Air recommendations placement)** · resolved · 2026-11-08 · app
  Context: user request — the raw counter rows are developer material, not consumer UI, and the
  Recommendations card now reads better at the end of the Air tab.
  Decision: the raw device-counter card moves from the Filter tab (deleted there) to the Device
  tab behind the existing developer-mode gate (`counters != null && devOptions`, 7-tap unlock).
  It absorbs the moved Dirty-air-time and Time-share-per-stage rows plus the persistence caption
  and Refresh. The Filter tab surfaces only health, basis + sensitivity, the reset placeholder
  and the explainer cards. The Air-tab Recommendations card is the LAST child of the page
  (after PM2.5 hero, PM1.0, PM10 — normal users see status first, advice after).
  Verified live on the A34 (gated-off and dev-unlocked states) and by tests (80/80: absence
  before unlock, moved rows + 0.3 h dirty read after; Filter-tab raw counters asserted gone).
  Follow-up (2026-11-08, same D): the Time-share-per-stage VALUE printed one line per air
  level (GOOD→HAZARD prefixes, `_kvLines` with a Flexible right column) — a single joined
  line grew unbounded and squeezed the key label into one-character lines. Live-verified
  with the seeded story (BAD 1955100s renders, label intact).

- **D-035 — Reconnect is a filter-alert trigger (bypasses the daily cap)** · resolved · 2026-11-08 · app
  Context: user report — reconnecting (demo + BLE) never re-presented the replacement modal.
  Cause: the connect handshake evaluation runs on every 'connected' event, but presenting was
  gated by the D-021 24 h re-alert interval, so a same-day re-present was impossible.
  Decision: `FilterAlertDecision.shouldNotify` gains `freshConnect` (connect-triggered
  evaluations bypass ONLY the 24 h interval; the health threshold and connected gates
  remain). `_onConnected` passes it; the 5-minute timer and `evaluateNow()` stay capped and
  `lastAlertMs` still stamps on every presentation. A degraded filter therefore re-surfaces
  at every attach; a healthy one never alerts. Both builds share this path (single fix →
  identical behavior for the demo's fake and the real v4.2.1 purifier).
  Verified by a service-level test with a connect-emitting fake (82/82): a connect event
  presents degraded health inside a 298-ms-old cap stamp, while a routine evaluation at the
  same age does not. Live: the seed-path modal re-confirmed on the A34; the kDebugMode
  `[filter-alert]` trail (evaluation inputs + decision) was added for G4-era diagnosis and
  prints nothing in release builds.

- **D-036 — Basis switching is developer-only; manual "I replaced the filter" reset on the Filter tab** · resolved · 2026-11-08 · app
  Context: user decision near panel-freeze — the consumer should not choose the replacement
  basis (pinned to dirty-air hours, the installed default D-027), and a manual replacement
  reset belongs in the Filter tab with a simple confirmation prompt (distinct from the alert
  modal's labels).
  Decision: the Filter tab loses the `Replacement basis` segmented control (sensitivity
  stays user-facing); the basis knob moves into Developer options on the Device tab as
  "Replacement basis (developer)" — same two segments, same engine, persisted via
  `settings.basis` exactly as before (explainer + health caption keep reflecting the active
  basis). The disabled Phase-5 `Reset filter counters` placeholder (D-010) is replaced by an
  enabled `I replaced the filter` FilledButton guarded by an AlertDialog ("Did you replace
  the filter?" / "Not yet" / "Yes, filter replaced") that performs the same reset as the
  alert modal's replacement action (`resetFilter` + invalidations + `lastAlertMs` re-arm)
  with a brief confirmation snackbar.
  Verified: widget tests — the Filter tab exposes no basis knob; the Device-tab dev knob
  flips `settings.basis` and the Filter-tab explainer switches to the load wording
  (82/82 incl. the D-035/D-036 suites); live on the A34 — Filter tab shows the new pinned
  consumer layout and the confirmation dialog with its labels captured; the dev-knob's
  dirty-air selection state confirmed via node dumps (widget-level proof of the flip).

### Backlog (unscheduled, non-blocking)

- AI-flagged v3 defects (particle wall-jitter bounce logic; boot progress outline only
  drawing when the first loop pass hits `elapsed == 0`) — **out of additive scope** (they are
  v3-baseline behavior; editing them breaks the §1.4 diff gate). Revisit as a v5-adjacent
  option ONLY if the user lifts the additive-only constraint.

- Rename Android `applicationId` from `com.example.docasa_app` before any distribution.
- Plan OQ #2 (fan voltage rail) — verify at next bench session; no app/firmware impact.
- ~~`tools/firmware-diff-check.sh` convenience script~~ — done in Phase 1 (D-015).
