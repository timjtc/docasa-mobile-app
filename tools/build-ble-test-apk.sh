#!/usr/bin/env bash
# Real-BLE G4 test artifact (D-017/D-019): flutter_blue_plus transport,
# release build signed with the debug key, parallel-installs as simply
# "DOCASA" next to the dev and demo builds (D-039).
# Runtime verification is expected at G4 — unverified against the device.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/development/flutter/bin:$PATH"
flutter build apk --dart-define=DOCASA_REAL_BLE=true -PrealBle=true
stamp=$(date +%Y%m%d)
mkdir -p releases
cp build/app/outputs/flutter-apk/app-release.apk "releases/docasa-ble-test-$stamp.apk"
echo "BLE test artifact: releases/docasa-ble-test-$stamp.apk"
