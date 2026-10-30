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
