Phone's still attached, so this is the whole loop for any future build:
export PATH="$HOME/development/flutter/bin:$PATH"

# 1. build (from the repo root ~/proj/docasa-app)
flutter build apk --debug

# 2. install (replaces the previous build, keeps app data)
~/Android/Sdk/platform-tools/adb install -r build/app/outputs/flutter-apk/app-debug.apk

# 3. launch
~/Android/Sdk/platform-tools/adb shell am start -n com.example.docasa_app/.MainActivity
Optional extras:
- Fresh data on first launch of a new build: data persists across reinstalls — to start clean: ~/Android/Sdk/platform-tools/adb shell pm clear com.example.docasa_app (then launch again; history DB resets).
- Log stream while testing (run in a second terminal before step 3): ~/Android/Sdk/platform-tools/adb logcat -s flutter
- If Android Studio is open with the device connected, flutter run from the IDE does build+install+launch in one step — same result.
Notes: -r reinstalls preserving data; if you change --dart-define=DOCASA_REAL_BLE=true later, that flag goes on the build line (flutter build apk --debug --dart-define=DOCASA_REAL_BLE=true) — outside G4 testing keep the default emulator build. When a build is actually broken to install, adb install fails with a reason line — copy that to me verbatim.

---

## Session log (2026-10-31, G4 practice on the A34)

- Launch note: the app-id suffix changes only the package name — the Activity class stays
  `com.example.docasa_app.MainActivity` for ALL variants:
  `adb shell am start -n com.example.docasa_app.ble/com.example.docasa_app.MainActivity` ✓
  or shorter: `adb shell monkey -p com.example.docasa_app.ble 1`.
- Artifacts (parallel-install by design):
  - `flutter build apk --debug` + `adb install -r build/app/outputs/flutter-apk/app-debug.apk` → dev build (`docasa_app`, emulator mode).
  - `bash tools/build-demo-apk.sh` → `releases/docasa-demo-<date>.apk` ("DOCASA Demo", emulator, release).
  - `bash tools/build-ble-test-apk.sh` → `releases/docasa-ble-test-<date>.apk` ("DOCASA BLE Test", real FBLP + picker, release).
- Log streams: `adb logcat -s flutter` (app debugPrints: `FBP: …`) and FBLP internals under tag `[FBP-Android]`.
- Observed: BT SCAN/CONNECT granted; permission gate no longer requires Location (API 31+
  neverForLocation); Connect → live picker sheet (valid DOCASA ads only, diagnostic list
  when none); handshake verifies DOCASA/DOCASA Air Purifier/4.x device info.
- Open item: zero DOCASA advertisements seen so far — purifier was never powered in range.
  Next step: bench day (flash v4.1.0 + G1/G2 per docs/Bench-Runbook.md), then the picker
  should surface `DOCASA-AirPurifier` and G4 proceeds.

## Session 3 (2026-11-01, maintainer flash + connect troubleshooting)

- More pull of the week: maintainer's Windows IDE fought FastLED (`objs.a` linker errors +
  OneDrive-corrupted archives) — fixes + troubleshooting table now in `firmware/README.md`;
  isolation sketches (FastLED-only, NimBLE-only) provided to prove library-vs-environment.
- v4.1.1 IS flashed on the purifier and the app's picker detects it
  ("service §D-002 · −61 dBm" row) — advertise path confirmed at the app level.
- Open issue: after selecting the device, the Air tab stays "Connecting…" — every failure
  stage maps to the same retry spinner, so the failing stage is unknown until probed:
  Serial (does `time sync` line appear?), nRF-connect G2 checklist (incl. 2A26==4.1.1,
  3× 1 Hz JSON subscribes), and `adb logcat -s flutter` FBP trail during a pick.
