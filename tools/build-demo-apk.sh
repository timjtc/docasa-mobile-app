#!/usr/bin/env bash
# Demo artifact export (user request): emulator mode, release build signed
# with the debug key, parallel-installs next to the dev build as "DOCASA Demo".
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/development/flutter/bin:$PATH"
flutter build apk -PdemoBuild=true
stamp=$(date +%Y%m%d)
mkdir -p releases
cp build/app/outputs/flutter-apk/app-release.apk "releases/docasa-demo-$stamp.apk"
echo "demo artifact: releases/docasa-demo-$stamp.apk"
