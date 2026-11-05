# Graph Report - docasa-mobile-app  (2026-11-05)

## Corpus Check
- 97 files · ~54,074 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 54 file(s) not represented in the graph (top: .xcconfig 8, (none) 7, .xml 7)

## Summary
- 1336 nodes · 1791 edges · 113 communities (70 shown, 43 thin omitted)
- Extraction: 94% EXTRACTED · 5% INFERRED · 1% AMBIGUOUS · INFERRED: 93 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `766c9869`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- ADB Test Workloop
- database.dart
- BLE Codec Contracts
- Fake BLE Connection State
- Apple Icon Asset Catalogs
- Settings Column Types
- BLE Connection Layer
- FBP Connection Core
- Fake BLE Telemetry Generator
- Air Quality Models
- GTK Flutter Embedder
- Package Dependencies
- Core Data Layer Imports
- CentOS Baseline Notes
- App Shell Imports
- Windows Flutter Shell
- History Bucketing Types
- Filter Health Stateful UI
- Linux Desktop Build
- Drift Database Root
- Web Favicon Assets
- Filter Health Engine
- BLE Characteristics Contract
- Device Page Imports
- Filter Budgets Core
- FBP Device Picker
- Ponytail Audit Skills
- History Repository
- Win32 Runner Resources
- Recording Service
- Windows Flutter Shell C++
- Number Formatting
- BLE UUID Contract
- Dashboard Widgets
- History Compactor SQL
- History Page Imports
- Local Notifications
- AppSetting
- Shared App Imports
- Air Stage Models
- macOS App Icon Set
- macOS Icon Densities
- win32_window.cpp
- Win32 Window Handler
- Docasa Brand Artwork
- Win32 Callback Types
- Fake Generator Imports
- App Theme Colors
- Size
- CentOS ACL Labs
- iOS Runner Shell
- Analyzer Lint Config
- Plugin Registrant Hook
- Session log — 2026-11-05: BLE "Connecting" hang triage (Windows host, post-handoff)
- AppDatabase
- Required Feature List
- iOS Launch Images
- Android Launcher Icons
- iOS Icon Density Slots
- iOS Icon Variants
- App Widget Companions
- PWA Maskable Icons
- Android MainActivity
- Android Icon Asset Family
- CentOS Link Concepts
- CentOS Network Labs
- iOS Icon Asset Sizes
- iOS Placeholder Icons
- iPad Icon Slots
- iPad Pro Icon Slot
- Launch Image Placeholder
- macOS Icon Catalog
- macOS 32px Icon Slot
- PWA Web Icons
- Agent Workflow Docs
- Android xxhdpi Icons
- Manual Connection Types
- docasa_connection.dart
- NimBLE Stack Choice
- Filter Lifetime NVS Model
- iOS Marketing Icon
- iOS App Icon Family
- iPhone 29pt Icon Slots
- iPhone Settings Icon
- iPhone Home Icon
- iPad 76pt Icon
- Android hdpi Icon
- CentOS nmap Notes
- Audit Workflow Method
- Phase 0 Contract Freeze
- Phase 6 Future Scope
- Flutter App Layering Plan
- Project Risk Plan
- PWM Fan Rework
- v3 Firmware Baseline
- iPad 29pt Icon
- Launch Asset Instructions
- Maskable 512 Asset

## God Nodes (most connected - your core abstractions)
1. `Decision Log (ADR-lite)` - 24 edges
2. `Win32Window` - 21 edges
3. `Bench Runbook — flashing & G1/G2 verification` - 16 edges
4. `Firmware README (ESP32/hardware)` - 13 edges
5. `Filter-Health Math — NVS counters to health % to projections` - 13 edges
6. `dependencies` - 12 edges
7. `Development Process` - 12 edges
8. `FlutterWindow` - 10 edges
9. `Gate G2 — BLE telemetry checklist (nRF Connect)` - 10 edges
10. `D-022 — Firmware v4.1.1 accepts resetFilter` - 10 edges

## Surprising Connections (you probably didn't know these)
- `arduino-cli flash procedure (upload --fqbn esp32:esp32:esp32)` --semantically_similar_to--> `Windows Arduino IDE flash procedure for v4.1.1`  [INFERRED] [semantically similar]
  docs/Bench-Runbook.md → firmware/README.md
- `ManualConnection` --implements--> `DocasaConnection`  [EXTRACTED]
  test/data/history_test.dart → lib/ble/docasa_connection.dart
- `D-003 — JSON v1 encoded with ArduinoJson 7.x` --references--> `ArduinoJson 7.4.3 (by Benoit Blanchon)`  [INFERRED]
  docs/Decision-Log.md → firmware/README.md
- `D-003 — JSON v1 encoded with ArduinoJson 7.x` --references--> `NimBLE-Arduino 2.5.2 (by h2zero)`  [INFERRED]
  docs/Decision-Log.md → firmware/README.md
- `Windows Arduino IDE flash procedure for v4.1.1` --references--> `D-022 — Firmware v4.1.1 accepts resetFilter`  [INFERRED]
  firmware/README.md → docs/Decision-Log.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Phase-gated lifecycle (Phases 0-6)** — docs_development_process_phase_gated_lifecycle, docs_development_process_phase_0_foundations, docs_development_process_phase_1_firmware_nvs, docs_development_process_phase_2_firmware_ble, docs_development_process_phase_3_app_core, docs_development_process_phase_4_app_device_integration, docs_development_process_phase_5_commands_security, docs_development_process_phase_6_future_deferred [EXTRACTED 1.00]
- **resetFilter write lifecycle (security ruling - alert flow - firmware acceptance)** — docs_bench_runbook_resetfilter_command, docs_decision_log_d_010, docs_decision_log_d_021, docs_decision_log_d_022, docs_filter_health_math_fansec_counter, docs_filter_health_math_pwfs_counter [EXTRACTED 1.00]
- **Ponytail Skill Family (6 skills: ponytail, review, audit, debt, gain, help; shared repo DietrichGebert/ponytail)** — commandcode_skills_ponytail_skill_ponytail_mode, commandcode_skills_ponytail_review_skill_ponytail_review_skill, commandcode_skills_ponytail_audit_skill_ponytail_audit_skill, commandcode_skills_ponytail_debt_skill_ponytail_debt_skill, commandcode_skills_ponytail_gain_skill_ponytail_gain_skill, commandcode_skills_ponytail_help_skill_ponytail_help_skill [EXTRACTED 1.00]
- **PWA app icon set (web/icons)** — web_icons_icon_192, web_icons_icon_512, web_icons_icon_maskable_192, web_icons_icon_maskable_512, web_manifest [EXTRACTED 1.00]
- **Docasa iOS Home-Screen Icon (stock Flutter artwork via AppIcon.appiconset)** — ios_runner_assets_xcassets_appicon_appiconset_icon_app_60x60_3x_app_icon, ios_runner_assets_xcassets_appicon_appiconset_icon_app_60x60_3x_appiconset, ios_runner_assets_xcassets_appicon_appiconset_icon_app_60x60_3x_docasa_app, ios_runner_assets_xcassets_appicon_appiconset_icon_app_60x60_3x_flutter_logo_artwork [INFERRED 0.75]
- **Docasa iOS home screen branding** — ios_runner_assets_xcassets_appicon_appiconset_icon_app_40x40_2x_image, ios_runner_assets_xcassets_appicon_appiconset_icon_app_40x40_2x_appiconset, ios_runner_assets_xcassets_appicon_appiconset_icon_app_40x40_2x_docasa_app [INFERRED 0.75]
- **iOS App Icon Family (AppIcon.appiconset iPad icon variants)** — ios_runner_assets_xcassets_appicon_appiconset_icon_app_76x76_1x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_76x76_1x_appicon_asset_set [INFERRED 0.75]
- **iOS app icon identity of the docasa Runner app** — ios_runner_assets_xcassets_appicon_appiconset_icon_app_20x20_1x_app_icon, ios_runner_assets_xcassets_appicon_appiconset_icon_app_20x20_1x_appiconset, ios_runner_assets_xcassets_appicon_appiconset_icon_app_20x20_1x_flutter_logo, ios_runner_assets_xcassets_appicon_appiconset_icon_app_20x20_1x_runner_app [INFERRED 0.75]
- **Web App Icon Asset Set (browser favicon plus PWA manifest icons)** — web_favicon, web_icons_icon_192, web_icons_icon_512, web_icons_icon_maskable_192, web_icons_icon_maskable_512 [INFERRED 0.75]
- **Filter Health Feature Chain** — docs_app_required_features_filter_health, docs_iot_integration_plan_filter_lifetime_model, docs_iot_integration_plan_nvs_counter_persistence, docs_ble_protocol_contract_filter_counters_characteristic, docs_ble_protocol_contract_command_characteristic [INFERRED 0.85]
- **LaunchImage density variant set (1x/2x/3x)** — ios_runner_assets_xcassets_launchimage_imageset_launchimage_2x_launchimage_2x, ios_runner_assets_xcassets_launchimage_imageset_launchimage_3x_launchimage_3x [INFERRED 0.85]
- **macOS AppIcon multi-density icon set (single artwork scaled 16-1024px)** — macos_runner_assets_xcassets_appicon_appiconset_app_icon_16_app_icon_16, macos_runner_assets_xcassets_appicon_appiconset_app_icon_32_app_icon_32, macos_runner_assets_xcassets_appicon_appiconset_app_icon_64_app_icon_64, macos_runner_assets_xcassets_appicon_appiconset_app_icon_128_app_icon_128, macos_runner_assets_xcassets_appicon_appiconset_app_icon_256_app_icon_256, macos_runner_assets_xcassets_appicon_appiconset_app_icon_512_app_icon_512, macos_runner_assets_xcassets_appicon_appiconset_app_icon_1024_app_icon_1024 [INFERRED 0.85]
- **Android ic_launcher density set** — android_app_src_main_res_mipmap_hdpi_ic_launcher_appicon [INFERRED 0.95]
- **Launcher icon resource set (@mipmap/ic_launcher) selected by screen density at runtime** — android_app_src_main_res_mipmap_xhdpi_ic_launcher, android_app_src_main_res_mipmap_xxxhdpi_ic_launcher [INFERRED 0.95]
- **AppIcon Asset Set (iOS app icon family: all resolutions + Contents.json manifest)** — ios_runner_assets_xcassets_appicon_appiconset_icon_app_29x29_1x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_29x29_3x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_60x60_2x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_76x76_1x [INFERRED 0.95]
- **Hardware bench flash & gate verification workflow** — docs_bench_runbook_flash_procedure_arduino_cli, docs_bench_runbook_gate_g1_persistence_behavior, docs_bench_runbook_gate_g2_ble_telemetry_checklist, docs_bench_runbook_nrf_connect, firmware_readme_windows_flash_procedure_v411 [INFERRED 0.95]
- **macOS AppIcon Size Variant Set (16-1024px)** — macos_runner_assets_xcassets_appicon_appiconset_app_icon_16, macos_runner_assets_xcassets_appicon_appiconset_app_icon_32, macos_runner_assets_xcassets_appicon_appiconset_app_icon_64, macos_runner_assets_xcassets_appicon_appiconset_app_icon_128, macos_runner_assets_xcassets_appicon_appiconset_app_icon_256, macos_runner_assets_xcassets_appicon_appiconset_app_icon_512, macos_runner_assets_xcassets_appicon_appiconset_app_icon_1024 [INFERRED 0.95]
- **Apache HTTP service bring-up and diagnosis under firewalld/SELinux** — assets_itso_quickie_notes___centos_httpd, assets_itso_quickie_notes___centos_firewalld, assets_itso_quickie_notes___centos_systemctl, assets_itso_quickie_notes___centos_selinux, assets_itso_quickie_notes___centos_lab_a4_package_service_firewall, assets_itso_quickie_notes___centos_lab_d1_broken_web_service [INFERRED]
- **Persistent XFS disk provisioning workflow (partition, format, UUID fstab mount)** — assets_itso_quickie_notes___centos_lab_a3_persistent_data_mount, assets_itso_quickie_notes___centos_fdisk, assets_itso_quickie_notes___centos_partprobe, assets_itso_quickie_notes___centos_mkfs_xfs, assets_itso_quickie_notes___centos_blkid, assets_itso_quickie_notes___centos_fstab, assets_itso_quickie_notes___centos_findmnt, assets_itso_quickie_notes___centos_xfs [INFERRED]
- **Unix file permission model (mode bits, special bits, ACLs)** — assets_itso_quickie_notes___centos_file_permissions, assets_itso_quickie_notes___centos_suid, assets_itso_quickie_notes___centos_sgid, assets_itso_quickie_notes___centos_sticky_bit, assets_itso_quickie_notes___centos_acl [INFERRED]

## Communities (113 total, 43 thin omitted)

### Community 0 - "ADB Test Workloop"
Cohesion: 0.05
Nodes (55): App ADB Test Notes, ADB build/install/launch loop, FBP debugPrint log tags (FBP: / [FBP-Android]), G4 practice session 2026-10-31 on A34, Parallel-install APK artifacts (dev / DOCASA Demo / DOCASA BLE Test), Samsung A34 test phone (SM-A346E, Android 14), Session 3: maintainer flash + connect troubleshooting (2026-11-01), Bench Runbook — flashing & G1/G2 verification (+47 more)

### Community 1 - "database.dart"
Cohesion: 0.04
Nodes (74): _, actualTableName, _alias, aliasedName, allSchemaEntities, allTables, attachedDatabase, batteryPct (+66 more)

### Community 2 - "BLE Codec Contracts"
Cohesion: 0.05
Nodes (37): decodeAirQuality, decodeEnvironment, decodeFilterCounters, decodeSystemStatus, DocasaCodec, encodeAirQuality, encodeEnvironment, encodeFilterCounters (+29 more)

### Community 3 - "Fake BLE Connection State"
Cohesion: 0.06
Nodes (29): FilterSettings, alertPresenterProvider, alertShouldUseInAppModal, AppLifecycle, build, bump, c, computeFilterHealth (+21 more)

### Community 4 - "Apple Icon Asset Catalogs"
Cohesion: 0.06
Nodes (15): Cocoa, Flutter, flutter_blue_plus_darwin, flutter_local_notifications, FlutterMacOS, Foundation, AppDelegate, SceneDelegate (+7 more)

### Community 5 - "Settings Column Types"
Cohesion: 0.06
Nodes (32): AppSettings, batteryPct, batteryV, charging, fanRpm, FilterEvents, HourAggregates, hourStartMs (+24 more)

### Community 6 - "BLE Connection Layer"
Cohesion: 0.08
Nodes (21): connect, disconnect, dispose, _gen, _lastTimeSyncEpoch, _onTick, _outageEverySec, readDeviceInfo (+13 more)

### Community 7 - "FBP Connection Core"
Cohesion: 0.06
Nodes (29): backoffDelay, connect, connectTo, _device, disconnect, dispose, _dropSub, _emit (+21 more)

### Community 8 - "Fake BLE Telemetry Generator"
Cohesion: 0.06
Nodes (30): 5, air, _battery, _charging, _chargingLeft, counters, elapsed, env (+22 more)

### Community 9 - "Air Quality Models"
Cohesion: 0.06
Nodes (31): air, AirQualitySample, at, batteryFull, batteryPct, batteryVoltage, charging, complete (+23 more)

### Community 10 - "GTK Flutter Embedder"
Cohesion: 0.09
Nodes (14): fl_register_plugins(), main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line() (+6 more)

### Community 11 - "Package Dependencies"
Cohesion: 0.07
Nodes (28): dependencies, cupertino_icons, drift, fl_chart, flutter, flutter_blue_plus, flutter_local_notifications, flutter_riverpod (+20 more)

### Community 12 - "Core Data Layer Imports"
Cohesion: 0.05
Nodes (28): main, main, main, budgets, counters, main, now, connect (+20 more)

### Community 13 - "CentOS Baseline Notes"
Cohesion: 0.10
Nodes (26): Bash Scripting (set -Eeuo pipefail sample scripts), blkid (Block Device UUIDs and FS Types), Cron Job Scheduler (crontab, crond, CRON FORMAT), DNF Package Manager (same commands as YUM), fdisk (Disk Partitioning), findmnt (Mount Inspection and fstab --verify), firewalld / firewall-cmd, fstab (/etc/fstab Persistent Mount via UUID) (+18 more)

### Community 14 - "App Shell Imports"
Cohesion: 0.10
Nodes (15): requestFilterAlertModal, _alertDialogOpen, _AppShellState, build, createState, didChangeAppLifecycleState, dispose, DocasaApp (+7 more)

### Community 15 - "Windows Flutter Shell"
Cohesion: 0.12
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 16 - "History Bucketing Types"
Cohesion: 0.10
Nodes (19): bucketCount, bucketMs, column, coverage, _floor, HistoryRepository, HistorySeries, isEmpty (+11 more)

### Community 17 - "Filter Health Stateful UI"
Cohesion: 0.10
Nodes (16): _budgetCard, _countersCard, createState, dispose, FilterPage, _FilterPageState, _healthCard, _healthColor (+8 more)

### Community 18 - "Linux Desktop Build"
Cohesion: 0.10
Nodes (22): APPLICATION_ID com.example.docasa_app (GTK app identifier), APPLY_STANDARD_SETTINGS (Linux: cxx_std_14, -Wall -Werror, -O3+NDEBUG outside Debug), BINARY_NAME docasa_app (Linux executable name), Linux Bundle Install (relocatable bundle under build dir; AOT lib installed only for non-Debug), linux/CMakeLists.txt (Linux desktop build config, CMake 3.13, project runner, C++14, GTK3 via pkg-config), flutter_assemble target (linux/flutter/CMakeLists.txt: tool_backend.sh, ephemeral libflutter_linux_gtk.so, icudtl.dat, libapp.so AOT), GTK/GLIB/GIO pkg-config dependencies (Flutter Linux embedder), Linux Runner Executable (main.cc, my_application.cc, generated_plugin_registrant.cc; links flutter + PkgConfig::GTK) (+14 more)

### Community 19 - "Drift Database Root"
Cohesion: 0.11
Nodes (12): _buffer, _db, flush, _flushInterval, _flushRows, _flushTimer, _onTelemetry, _recorded (+4 more)

### Community 20 - "Web Favicon Assets"
Cohesion: 0.10
Nodes (20): Flutter default launcher icon (template branding asset), Web Favicon (favicon.png, 16x16 8-bit RGBA browser icon), Browser Tab Icon Role (rel=icon link target declared in web/index.html), Icon artwork: likely stock Flutter logo favicon from flutter create template (visual content unverified, vision unavailable), Icon-192.png - PWA app icon, 192x192 8-bit RGB PNG (visual content unverified), Icon-512.png - PWA app icon, 512x512 8-bit RGB PNG (visual content unverified), App Brand Logo (icon visual content, unverified), PWA Icon Family (web/icons: Icon-192, Icon-512, maskable variants, manifest-listed) (+12 more)

### Community 21 - "Filter Health Engine"
Cohesion: 0.10
Nodes (17): computeFilterHealth, consumed, estimateLoadRatePerDay, FilterHealth, hourBudgetRpmS, hourFrac, loadBinding, loadBudgetRpmUgS (+9 more)

### Community 22 - "BLE Characteristics Contract"
Cohesion: 0.10
Nodes (19): Air Quality Characteristic (JSON v1), Command Characteristic (write), App Connect Handshake, BLE Protocol Contract v1.0, Environment Characteristic (JSON v1), Filter Counters Characteristic (read-only), Golden Test Fixtures F1-F7 / X1-X6, JSON v1 Payload Format (+11 more)

### Community 23 - "Device Page Imports"
Cohesion: 0.11
Nodes (13): build, child, color, connState, icon, label, pm25, stage (+5 more)

### Community 24 - "Filter Budgets Core"
Cohesion: 0.11
Nodes (16): FilterBudgets, alertThresholdPct, budgets, copyWith, _db, filterAlertAckMs, _kAck, _kHourBudget (+8 more)

### Community 25 - "FBP Device Picker"
Cohesion: 0.09
Nodes (15): build, conn, createState, dev, _DevicePickerSheet, _DevicePickerSheetState, dispose, initState (+7 more)

### Community 26 - "Ponytail Audit Skills"
Cohesion: 0.11
Nodes (19): Audit Evidence Rules (concrete failure case required; grep tree incl. tests/fixtures/config before calling code unused; shortcut: comment is a decision not a finding unless load crosses it), Audit Finding Categories (bug, risk/security+data loss, scale/load, missing test, speed, lean), ponytail-audit Skill (whole-repo quality audit, ranked, one-shot), Debt Ledger Row (file:line, what was simplified, ceiling, upgrade trigger; no-trigger rows flagged as rot risk), ponytail-debt Skill (harvest shortcut: comments into one debt ledger), Ponytail Benchmark Figures (Opus 5.5, 39 tasks x 5 runs, 18 with hidden checks; LOC 47%, output tokens 55%, cost 74%, time 59%; hidden checks 97% vs 96%; tests where logic needs one 98% vs 68%), Ponytail Honesty Boundary (benchmark averages only; never invent per-repo savings; real per-repo figures come from /ponytail-debt), ponytail-gain Skill (measured-impact scoreboard, one-shot display) (+11 more)

### Community 27 - "History Repository"
Cohesion: 0.13
Nodes (12): HistoryMetric, HistoryRange, _axisStyle, _chart, createState, _donutCard, _legendRow, _metric (+4 more)

### Community 28 - "Win32 Runner Resources"
Cohesion: 0.18
Nodes (6): Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_, WindowClassRegistrar::UnregisterWindowClass()

### Community 29 - "Recording Service"
Cohesion: 0.11
Nodes (15): _alerts, _alertTimer, compactor, _compactTimer, _db, _defaultNow, dispose, _evaluateAlerts (+7 more)

### Community 30 - "Windows Flutter Shell C++"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 31 - "Number Formatting"
Cohesion: 0.11
Nodes (17): bigInt, coveragePct, _d1, date, dateTime, daysFromNow, fanSecondsAsHours, Fmt (+9 more)

### Community 32 - "BLE UUID Contract"
Cohesion: 0.11
Nodes (17): airQualityUuid, batteryLevelUuid, batteryServiceUuid, commandUuid, deviceInformationServiceUuid, deviceName, DocasaContract, environmentUuid (+9 more)

### Community 33 - "Dashboard Widgets"
Cohesion: 0.15
Nodes (20): build, DashboardPage, SystemPage, build, DevicePage, startConnectFlow, build, _FilterReplaceDialog (+12 more)

### Community 34 - "History Compactor SQL"
Cohesion: 0.12
Nodes (13): _avgCols, customUpdate, HistoryCompactor, hour_aggregates, _hourAggSql, hourRetentionMs, minute_aggregates, _minuteAggSql (+5 more)

### Community 35 - "History Page Imports"
Cohesion: 0.17
Nodes (3): _body, _kv, showFilterReplaceModal

### Community 36 - "Local Notifications"
Cohesion: 0.14
Nodes (12): didLaunchFromFilter, FilterAlertDecision, FilterAlertPort, _init, LocalFilterAlertPort, NoopFilterAlertPort, _payload, _plugin (+4 more)

### Community 37 - "AppSetting"
Cohesion: 0.26
Nodes (10): AppSetting, AppSettingsCompanion, FilterEvent, FilterEventsCompanion, HourAggregate, HourAggregatesCompanion, MinuteAggregate, MinuteAggregatesCompanion (+2 more)

### Community 38 - "Shared App Imports"
Cohesion: 0.12
Nodes (4): main, main, _now, t

### Community 39 - "Air Stage Models"
Cohesion: 0.17
Nodes (10): AirStage, batteryPct, clamped, color, DomainClamps, fanRpm, fromIndex, index1 (+2 more)

### Community 40 - "macOS App Icon Set"
Cohesion: 0.18
Nodes (12): macOS App Icon 1024px (app_icon_1024.png), macOS App Icon 128x128 @1x (app_icon_128.png, PNG 128x128 8-bit RGBA), AppIcon.appiconset macOS Asset Set (10 catalog entries, 16-1024px, 1x/2x), Docasa App Visual Identity (icon artwork content), macOS App Icon 16px (app_icon_16.png), macOS App Icon 256px (app_icon_256.png), macOS App Icon 32x32 (AppIcon.appiconset variant; serves 16x16@2x and 32x32@1x per Contents.json; visual content unverified - vision unavailable), macOS App Icon 512px (app_icon_512.png) (+4 more)

### Community 41 - "macOS Icon Densities"
Cohesion: 0.18
Nodes (11): App Icon 1024px (macOS Runner density variant, 512x512@2x), App Icon 128px (macOS Runner density variant, 128x128@1x), App Icon 16px (macOS Runner density variant, 16x16@1x), App Icon 256px (macOS Runner, 256x256@1x and 128x128@2x), Docasa App Icon Artwork (visual content unverified - vision unavailable), App Icon 32px (macOS Runner density variant, 32x32@1x and 16x16@2x), App Icon 512px (macOS Runner density variant, 512x512@1x and 256x256@2x), App Icon 64px (macOS Runner density variant, 32x32@2x) (+3 more)

### Community 43 - "Win32 Window Handler"
Cohesion: 0.18
Nodes (7): Point, x, y, Win32Window, child_content_, quit_on_close_, window_handle_

### Community 44 - "Docasa Brand Artwork"
Cohesion: 0.31
Nodes (10): Airflow Swoosh Motif (Clean Air Stream Lines), Angular Bent Device Shape (Maroon / Olive / Navy / Teal Segments), Dark Theme Banner Variant Design, Docasa Brand Mark (DOCASA Wordmark), Docasa Logo Banner (Dark, Transparent PNG), 'Portable Air Purifier' Tagline / Product Positioning, Docasa Brand, Light Theme Banner Variant (+2 more)

### Community 46 - "Fake Generator Imports"
Cohesion: 0.22
Nodes (4): _chunk, HistorySeeder, _insert, seed

### Community 47 - "App Theme Colors"
Cohesion: 0.25
Nodes (6): accent, cardBg, dark, DocasaTheme, light, scaffoldBg

### Community 48 - "Size"
Cohesion: 0.50
Nodes (3): Size, height, width

### Community 49 - "CentOS ACL Labs"
Cohesion: 0.38
Nodes (7): ACL (Access Control List, getfacl/setfacl), File Permissions (chmod, chown, chgrp, umask 666-0022=644), Lab A1 - ACL-based Shared Workspace, Lab E2 - User and Group Creation, SGID (Set Group ID, chmod 2755 / g+s), Sticky Bit (chmod 1777 / o+t), SUID (Set User ID, chmod 4755 / u+s)

### Community 50 - "iOS Runner Shell"
Cohesion: 0.38
Nodes (7): Docasa iOS Runner App (Flutter iOS shell), AppIcon.appiconset (iOS app icon asset set), iOS App Icon 20x20@2x (40x40 PNG, unmodified Flutter default logo), App Icon (Docasa mobile app visual identity), Flutter SDK Default App Icon (template artwork), Docasa iOS App Icon 40x40@1x (iPad), Flutter default placeholder app icon

### Community 51 - "Analyzer Lint Config"
Cohesion: 0.33
Nodes (5): analyzer, exclude, include, linter, rules

### Community 53 - "Session log — 2026-11-05: BLE "Connecting" hang triage (Windows host, post-handoff)"
Cohesion: 0.33
Nodes (5): Findings, Fix (D-025), Follow-ups, Procedure (methodically executed), Session log — 2026-11-05: BLE "Connecting" hang triage (Windows host, post-handoff)

### Community 55 - "Required Feature List"
Cohesion: 0.60
Nodes (5): Required App Feature List, Requirement 3: Filter Health Monitoring and Replacement Alerts, Requirement 2: Day/Week/Month Air-Quality History, Requirement 1: Realtime AQ Readings and System Status, Requirement Traceability Matrix (Plan section 10)

### Community 56 - "iOS Launch Images"
Cohesion: 0.40
Nodes (4): iOS launch screen placeholder visual (LaunchImage asset), Blank transparent 1x1 placeholder pixel (inferred visual content of Flutter template launch image, unverified), LaunchImage@3x.png (iOS launch screen image, 3x density variant, 1x1 8-bit gray+alpha PNG), LaunchImage asset set (iOS launch screen image registered in Contents.json with 1x/2x/3x density variants)

### Community 57 - "Android Launcher Icons"
Cohesion: 0.67
Nodes (4): Docasa App Launcher Icon (xhdpi density), Docasa App Launcher Icon (ic_launcher, xxxhdpi, 192x192, 8-bit palette PNG; pixel content not visually verified), Docasa App Visual Identity, Android Launcher Icon Density Family (ic_launcher across mipmap mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi)

### Community 58 - "iOS Icon Density Slots"
Cohesion: 0.50
Nodes (4): iOS App Icon 20x20@1x (iPad 20pt @1x slot) - default Flutter logo, AppIcon.appiconset - iOS icon family (iPhone/iPad/marketing size variants), Flutter default logo icon design (Flutter blues #54C5F8 / #01579B on white), Flutter iOS Runner host app (docasa-app)

### Community 59 - "iOS Icon Variants"
Cohesion: 0.67
Nodes (4): iOS App Icon 60x60@3x (180x180 px, blue Flutter-logo mark on white), AppIcon.appiconset (iOS icon asset set, 16 size variants), Docasa App (iOS bundle, CFBundleDisplayName 'Docasa App'), Stock Flutter Template Icon Artwork (Flutter logo blues #54C5F8/#29B6F6/#01579B on white)

### Community 61 - "App Widget Companions"
Cohesion: 0.50
Nodes (3): ConnectionChip, StageHero, ValueTile

### Community 62 - "PWA Maskable Icons"
Cohesion: 0.50
Nodes (4): Icon-maskable-512.png (512x512 8-bit RGBA PNG, PWA maskable app icon), Icon-maskable-512 Depicted Artwork (visual content unverified - vision unavailable), Docasa PWA Icon Asset Family (web/icons: Icon-192, Icon-512, Icon-maskable-192, Icon-maskable-512), PWA Maskable Icon Format (safe-zone adaptive icon)

### Community 64 - "Android Icon Asset Family"
Cohesion: 0.67
Nodes (3): App Launcher Visual Identity (ic_launcher asset), ic_launcher.png (mdpi launcher icon, 48x48), Android Launcher Icon Density Set

### Community 65 - "CentOS Link Concepts"
Cohesion: 0.67
Nodes (3): Hard Link (points to same INODE), INODE (storage location shown by ls -li), Symbolic Link (hyperlink/shortcut, ln -s)

### Community 66 - "CentOS Network Labs"
Cohesion: 1.00
Nodes (3): Lab A2 - Network Diagnosis and Static Profile, NetworkManager, nmcli (NetworkManager CLI, static IPv4 config)

### Community 67 - "iOS Icon Asset Sizes"
Cohesion: 0.67
Nodes (3): AppIcon.appiconset (iOS asset catalog icon set), Docasa App (docasa_app, Flutter iOS build target branding), iOS App Icon 40x40@2x (Docasa, 80x80px Spotlight/Settings slot)

### Community 68 - "iOS Placeholder Icons"
Cohesion: 0.67
Nodes (3): iOS App Icon 40x40@3x (120px PNG, iPhone slot), AppIcon Asset Set (iOS icon family), Default Flutter Placeholder Branding (light gray background, teal/blue glyph)

### Community 69 - "iPad Icon Slots"
Cohesion: 0.67
Nodes (3): iOS App Icon 76x76@1x (iPad), AppIcon Asset Set (iOS Runner asset catalog icon family), Icon artwork: likely stock Flutter logo (white background, Material light blue palette)

### Community 70 - "iPad Pro Icon Slot"
Cohesion: 0.67
Nodes (3): iOS App Icon 83.5x83.5@2x (iPad, Runner), AppIcon Asset Set (iOS Runner), Icon artwork (visual content unverified, vision unavailable; 167x167 8-bit colormap PNG)

### Community 71 - "Launch Image Placeholder"
Cohesion: 0.67
Nodes (3): LaunchImage.png (iOS launch image asset, 1x1 placeholder), iOS Launch Screen Image Concept, Transparent Placeholder Pixel Concept

### Community 72 - "macOS Icon Catalog"
Cohesion: 0.67
Nodes (3): macOS AppIcon asset set (multi-density icon variants 16-1024px + Contents.json manifest), macOS App Icon 1024x1024 PNG (AppIcon.appiconset, 512x512 @2x master variant), App icon visual content (unverified - vision unavailable in this run)

### Community 73 - "macOS 32px Icon Slot"
Cohesion: 0.67
Nodes (3): 32x32 Density Variant of macOS App Icon, Flutter Logo Mark (32px Icon Artwork), App Icon 32px (PNG)

### Community 74 - "PWA Web Icons"
Cohesion: 0.67
Nodes (3): PWA Maskable App Icon 192x192 (web/icons), Icon artwork (visual content unverified, vision unavailable; 192x192 8-bit RGBA PNG, maskable safe-zone), PWA Icon Set (web/manifest.json icons: Icon-192, Icon-512, Icon-maskable-192, Icon-maskable-512; this asset purpose=maskable)

### Community 78 - "docasa_connection.dart"
Cohesion: 0.14
Nodes (12): connect, disconnect, dispose, DocasaConnection, readDeviceInfo, readFilterCounters, resetFilter, states (+4 more)

## Ambiguous Edges - Review These
- `macOS App Icon 1024x1024 PNG (AppIcon.appiconset, 512x512 @2x master variant)` → `App icon visual content (unverified - vision unavailable in this run)`  [AMBIGUOUS]
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png · relation: conceptually_related_to
- `onSec — merged power-on seconds counter (u32)` → `Filter-Health Math — NVS counters to health % to projections`  [AMBIGUOUS]
  docs/Filter-Health-Math.md · relation: conceptually_related_to
- `Flutter default launcher icon (template branding asset)` → `Icon-192.png - PWA app icon, 192x192 8-bit RGB PNG (visual content unverified)`  [AMBIGUOUS]
  web/icons/Icon-192.png · relation: conceptually_related_to
- `App Brand Logo (icon visual content, unverified)` → `Icon-512.png - PWA app icon, 512x512 8-bit RGB PNG (visual content unverified)`  [AMBIGUOUS]
  web/icons/Icon-512.png · relation: conceptually_related_to
- `Web Favicon (favicon.png, 16x16 8-bit RGBA browser icon)` → `Icon artwork: likely stock Flutter logo favicon from flutter create template (visual content unverified, vision unavailable)`  [AMBIGUOUS]
  web/favicon.png · relation: conceptually_related_to
- `Docasa App Visual Identity (icon artwork content)` → `macOS App Icon 128x128 @1x (app_icon_128.png, PNG 128x128 8-bit RGBA)`  [AMBIGUOUS]
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png · relation: conceptually_related_to
- `Visual content of app_icon_512.png (unverified - vision unavailable)` → `macOS App Icon 512px (app_icon_512.png)`  [AMBIGUOUS]
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png · relation: conceptually_related_to
- `macOS App Icon 1024px (app_icon_1024.png)` → `macOS App Icon 16px (app_icon_16.png)`  [AMBIGUOUS]
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png · relation: conceptually_related_to
- `Docasa App Icon Artwork (visual content unverified - vision unavailable)` → `App Icon 256px (macOS Runner, 256x256@1x and 128x128@2x)`  [AMBIGUOUS]
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png · relation: conceptually_related_to
- `Flutter Default macOS Template Icon (possible unverified artwork)` → `App Icon 64px (macOS Runner density variant, 32x32@2x)`  [AMBIGUOUS]
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png · relation: implements
- `Angular Bent Device Shape (Maroon / Olive / Navy / Teal Segments)` → `'Portable Air Purifier' Tagline / Product Positioning`  [AMBIGUOUS]
  assets/docasa-logo-banner-dark-t.png · relation: conceptually_related_to
- `Flutter default placeholder app icon` → `Docasa iOS App Icon 40x40@1x (iPad)`  [AMBIGUOUS]
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png · relation: conceptually_related_to
- `iOS launch screen placeholder visual (LaunchImage asset)` → `LaunchImage@2x.png`  [AMBIGUOUS]
  ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png · relation: implements
- `Blank transparent 1x1 placeholder pixel (inferred visual content of Flutter template launch image, unverified)` → `LaunchImage@3x.png (iOS launch screen image, 3x density variant, 1x1 8-bit gray+alpha PNG)`  [AMBIGUOUS]
  ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png · relation: conceptually_related_to
- `Docasa App Visual Identity` → `Docasa App Launcher Icon (ic_launcher, xxxhdpi, 192x192, 8-bit palette PNG; pixel content not visually verified)`  [AMBIGUOUS]
  android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png · relation: conceptually_related_to
- `Icon-maskable-512 Depicted Artwork (visual content unverified - vision unavailable)` → `Icon-maskable-512.png (512x512 8-bit RGBA PNG, PWA maskable app icon)`  [AMBIGUOUS]
  web/icons/Icon-maskable-512.png · relation: references
- `iOS App Icon 83.5x83.5@2x (iPad, Runner)` → `Icon artwork (visual content unverified, vision unavailable; 167x167 8-bit colormap PNG)`  [AMBIGUOUS]
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png · relation: conceptually_related_to
- `Transparent Placeholder Pixel Concept` → `LaunchImage.png (iOS launch image asset, 1x1 placeholder)`  [AMBIGUOUS]
  ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png · relation: references
- `PWA Maskable App Icon 192x192 (web/icons)` → `Icon artwork (visual content unverified, vision unavailable; 192x192 8-bit RGBA PNG, maskable safe-zone)`  [AMBIGUOUS]
  web/icons/Icon-maskable-192.png · relation: conceptually_related_to

## Knowledge Gaps
- **590 isolated node(s):** `states`, `telemetry`, `readDeviceInfo`, `readFilterCounters`, `syncTime` (+585 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 783 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **43 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AppDatabase` connect `AppDatabase` to `database.dart`, `Fake BLE Connection State`, `Core Data Layer Imports`, `Drift Database Root`, `Filter Budgets Core`, `Recording Service`?**
  _High betweenness centrality (0.057) - this node is a cross-community bridge._
- **What connects `states`, `telemetry`, `readDeviceInfo` to the rest of the system?**
  _590 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `ADB Test Workloop` be split into smaller, more focused modules?**
  _Cohesion score 0.05067920585161965 - nodes in this community are weakly interconnected._
- **Why does `Win32Window` connect `Win32 Window Handler` to `win32_window.cpp`, `Win32 Callback Types`, `Windows Flutter Shell`, `Size`, `Win32 Runner Resources`, `Windows Flutter Shell C++`?**
  _High betweenness centrality (0.028) - this node is a cross-community bridge._
- **Should `database.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04223469660518578 - nodes in this community are weakly interconnected._

### Low-confidence Hints
_AMBIGUOUS edges — the extractor was unsure. Verify before acting on these._

- **What is the exact relationship between `macOS App Icon 1024x1024 PNG (AppIcon.appiconset, 512x512 @2x master variant)` and `App icon visual content (unverified - vision unavailable in this run)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `onSec — merged power-on seconds counter (u32)` and `Filter-Health Math — NVS counters to health % to projections`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._