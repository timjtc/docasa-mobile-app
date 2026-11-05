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

### Backlog (unscheduled, non-blocking)

- AI-flagged v3 defects (particle wall-jitter bounce logic; boot progress outline only
  drawing when the first loop pass hits `elapsed == 0`) — **out of additive scope** (they are
  v3-baseline behavior; editing them breaks the §1.4 diff gate). Revisit as a v5-adjacent
  option ONLY if the user lifts the additive-only constraint.

- Rename Android `applicationId` from `com.example.docasa_app` before any distribution.
- Plan OQ #2 (fan voltage rail) — verify at next bench session; no app/firmware impact.
- ~~`tools/firmware-diff-check.sh` convenience script~~ — done in Phase 1 (D-015).
