# Graph Report - docasa-app  (2026-10-31)

## Corpus Check
- Corpus is ~46,107 words - fits in a single context window. You may not need a graph.

## Summary
- 1099 nodes · 1406 edges · 94 communities (62 shown, 32 thin omitted)
- Extraction: 94% EXTRACTED · 5% INFERRED · 1% AMBIGUOUS · INFERRED: 69 edges (avg confidence: 0.88)
- Token cost: 59,520 input · 9,400 output

## Community Hubs (Navigation)
- Drift Column Schema
- Database Persistence Layer
- BLE Codec Contracts
- Apple Icon Asset Catalogs
- Settings Column Types
- BLE Connection Layer
- Fake BLE Telemetry Generator
- Air Quality Models
- GTK Flutter Embedder
- App Data Services
- Core Data Layer Imports
- Package Dependencies
- History Repository UI Data
- Windows Runner C++ Core
- History Bucketing Types
- Linux Desktop Build
- Web Favicon Assets
- Filter Health Engine
- BLE Telemetry Streams
- Ponytail Audit Skills
- Win32 Window Bracing
- Recording Service
- Windows Flutter Shell
- Number Formatting
- Riverpod Feature Pages
- Filter Budget Dashboard
- Filter Budget Settings
- Shared App Imports
- Dashboard Widgets
- Reusable UI Widgets
- Drift Settings Data Classes
- Air Stage Models
- macOS App Icon Set
- Filter Page Relative Imports
- BLE Protocol Governance
- macOS Icon Densities
- Widget Test Imports
- Win32 Window Handler
- BLE Characteristics Map
- Win32 Callback Types
- Fake Generator Imports
- Persistence Gate Plans
- Architecture Decisions
- App Theme Colors
- Win32 Point Geometry
- iOS Runner Shell
- Analyzer Lint Config
- Bench Gate G2 Plan
- Development Governance Doc
- Plugin Registrant Hook
- Required Feature List
- iOS Launch Images
- App Widget Companions
- Android Launcher Icons
- iOS Icon Density Slots
- iOS Icon Variants
- PWA Maskable Icons
- Drift Database Definition
- Android MainActivity
- Android Icon Asset Family
- iOS Icon Asset Sizes
- iOS Placeholder Icons
- iPad Icon Slots
- iPad Pro Icon Slot
- Launch Image Placeholder
- macOS Icon Catalog
- PWA Web Icons
- Agent Workflow Docs
- Android xxhdpi Icons
- Manual Connection Types
- Firmware Dependency Decisions
- NimBLE Stack Choice
- iOS Marketing Icon
- iOS App Icon Family
- iPhone Icon Slots
- iPhone Settings Icon
- iPhone Home Icon
- iPad 76pt Icon
- Firmware Diff Script
- Android hdpi Icon
- Audit Workflow Method
- ESP32 Module Decision
- Android Target Decision
- Flutter App Layering Plan
- Project Risk Plan
- PWM Fan Rework
- iPad 29pt Icon
- Launch Asset Instructions
- Maskable 512 Asset

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 21 edges
2. `dependencies` - 11 edges
3. `FlutterWindow` - 10 edges
4. `Runner Windows Executable (BINARY_NAME)` - 10 edges
5. `Ponytail Skill (lazy senior dev mode, MIT, github.com/DietrichGebert/ponytail)` - 10 edges
6. `AppDatabase` - 8 edges
7. `DevicePage` - 8 edges
8. `BLE Protocol Contract v1.0` - 8 edges
9. `DOCASA Telemetry Service (d0ca5a0e-...)` - 8 edges
10. `build` - 7 edges

## Surprising Connections (you probably didn't know these)
- `ManualConnection` --implements--> `DocasaConnection`  [EXTRACTED]
  test/data/history_test.dart → lib/ble/docasa_connection.dart
- `web/index.html - Flutter web entry page referencing the icon as apple-touch-icon` --references--> `Icon-192.png - PWA app icon, 192x192 8-bit RGB PNG (visual content unverified)`  [EXTRACTED]
  web/index.html → web/icons/Icon-192.png
- `linux/CMakeLists.txt (Linux desktop build config, CMake 3.13, project runner, C++14, GTK3 via pkg-config)` --conceptually_related_to--> `windows/CMakeLists.txt (Windows desktop build config, CMake 3.14, multi-config Debug/Profile/Release, Unicode, C++17, /W4 /WX /EHsc)`  [INFERRED]
  linux/CMakeLists.txt → windows/CMakeLists.txt
- `web/index.html (Flutter web shell: base href $FLUTTER_BASE_HREF, docasa_app title, manifest.json, favicon.png, apple-touch Icon-192, flutter_bootstrap.js)` --conceptually_related_to--> `BINARY_NAME docasa_app (Linux executable name)`  [INFERRED]
  web/index.html → linux/CMakeLists.txt
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Frozen Contract Governance Chain** — docs_iot_integration_plan_plan_v1, docs_ble_protocol_contract_contract_v1, docs_development_process_process_v1, docs_development_process_document_governance, docs_development_process_behavior_preservation_gate [INFERRED 0.90]
- **Filter Health Feature Chain** — docs_app_required_features_filter_health, docs_iot_integration_plan_filter_lifetime_model, docs_iot_integration_plan_nvs_counter_persistence, docs_ble_protocol_contract_filter_counters_characteristic, docs_ble_protocol_contract_command_characteristic, docs_decision_log_d004_uint64_nvs_counters, docs_decision_log_d011_filter_budgets [INFERRED 0.85]
- **Phase-Gated Verification Chain** — docs_development_process_phase_gated_lifecycle, docs_gate_reports_g0_gate_report, docs_gate_reports_g3_gate_report, docs_bench_runbook_g1_checks, docs_bench_runbook_g2_checks, docs_development_process_definition_of_done [INFERRED 0.90]
- **Android ic_launcher density set** — android_app_src_main_res_mipmap_hdpi_ic_launcher_appicon [INFERRED 0.95]
- **Launcher icon resource set (@mipmap/ic_launcher) selected by screen density at runtime** — android_app_src_main_res_mipmap_xhdpi_ic_launcher, android_app_src_main_res_mipmap_xxxhdpi_ic_launcher [INFERRED 0.95]
- **iOS app icon identity of the docasa Runner app** — ios_runner_assets_xcassets_appicon_appiconset_icon_app_20x20_1x_app_icon, ios_runner_assets_xcassets_appicon_appiconset_icon_app_20x20_1x_appiconset, ios_runner_assets_xcassets_appicon_appiconset_icon_app_20x20_1x_flutter_logo, ios_runner_assets_xcassets_appicon_appiconset_icon_app_20x20_1x_runner_app [INFERRED 0.75]
- **AppIcon Asset Set (iOS app icon family: all resolutions + Contents.json manifest)** — ios_runner_assets_xcassets_appicon_appiconset_icon_app_29x29_1x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_29x29_3x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_60x60_2x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_76x76_1x [INFERRED 0.95]
- **Docasa iOS home screen branding** — ios_runner_assets_xcassets_appicon_appiconset_icon_app_40x40_2x_image, ios_runner_assets_xcassets_appicon_appiconset_icon_app_40x40_2x_appiconset, ios_runner_assets_xcassets_appicon_appiconset_icon_app_40x40_2x_docasa_app [INFERRED 0.75]
- **Docasa iOS Home-Screen Icon (stock Flutter artwork via AppIcon.appiconset)** — ios_runner_assets_xcassets_appicon_appiconset_icon_app_60x60_3x_app_icon, ios_runner_assets_xcassets_appicon_appiconset_icon_app_60x60_3x_appiconset, ios_runner_assets_xcassets_appicon_appiconset_icon_app_60x60_3x_docasa_app, ios_runner_assets_xcassets_appicon_appiconset_icon_app_60x60_3x_flutter_logo_artwork [INFERRED 0.75]
- **iOS App Icon Family (AppIcon.appiconset iPad icon variants)** — ios_runner_assets_xcassets_appicon_appiconset_icon_app_76x76_1x, ios_runner_assets_xcassets_appicon_appiconset_icon_app_76x76_1x_appicon_asset_set [INFERRED 0.75]
- **LaunchImage density variant set (1x/2x/3x)** — ios_runner_assets_xcassets_launchimage_imageset_launchimage_2x_launchimage_2x, ios_runner_assets_xcassets_launchimage_imageset_launchimage_3x_launchimage_3x [INFERRED 0.85]
- **macOS AppIcon Size Variant Set (16-1024px)** — macos_runner_assets_xcassets_appicon_appiconset_app_icon_16, macos_runner_assets_xcassets_appicon_appiconset_app_icon_32, macos_runner_assets_xcassets_appicon_appiconset_app_icon_64, macos_runner_assets_xcassets_appicon_appiconset_app_icon_128, macos_runner_assets_xcassets_appicon_appiconset_app_icon_256, macos_runner_assets_xcassets_appicon_appiconset_app_icon_512, macos_runner_assets_xcassets_appicon_appiconset_app_icon_1024 [INFERRED 0.95]
- **macOS AppIcon multi-density icon set (single artwork scaled 16-1024px)** — macos_runner_assets_xcassets_appicon_appiconset_app_icon_16_app_icon_16, macos_runner_assets_xcassets_appicon_appiconset_app_icon_32_app_icon_32, macos_runner_assets_xcassets_appicon_appiconset_app_icon_64_app_icon_64, macos_runner_assets_xcassets_appicon_appiconset_app_icon_128_app_icon_128, macos_runner_assets_xcassets_appicon_appiconset_app_icon_256_app_icon_256, macos_runner_assets_xcassets_appicon_appiconset_app_icon_512_app_icon_512, macos_runner_assets_xcassets_appicon_appiconset_app_icon_1024_app_icon_1024 [INFERRED 0.85]
- **Web App Icon Asset Set (browser favicon plus PWA manifest icons)** — web_favicon, web_icons_icon_192, web_icons_icon_512, web_icons_icon_maskable_192, web_icons_icon_maskable_512 [INFERRED 0.75]
- **PWA app icon set (web/icons)** — web_icons_icon_192, web_icons_icon_512, web_icons_icon_maskable_192, web_icons_icon_maskable_512, web_manifest [EXTRACTED 1.00]
- **Ponytail Skill Family (6 skills: ponytail, review, audit, debt, gain, help; shared repo DietrichGebert/ponytail)** — commandcode_skills_ponytail_skill_ponytail_mode, commandcode_skills_ponytail_review_skill_ponytail_review_skill, commandcode_skills_ponytail_audit_skill_ponytail_audit_skill, commandcode_skills_ponytail_debt_skill_ponytail_debt_skill, commandcode_skills_ponytail_gain_skill_ponytail_gain_skill, commandcode_skills_ponytail_help_skill_ponytail_help_skill [EXTRACTED 1.00]

## Communities (94 total, 32 thin omitted)

### Community 0 - "Drift Column Schema"
Cohesion: 0.04
Nodes (74): _, actualTableName, _alias, aliasedName, allSchemaEntities, allTables, attachedDatabase, batteryPct (+66 more)

### Community 1 - "Database Persistence Layer"
Cohesion: 0.04
Nodes (39): _avgCols, customUpdate, HistoryCompactor, hour_aggregates, _hourAggSql, hourRetentionMs, minute_aggregates, _minuteAggSql (+31 more)

### Community 2 - "BLE Codec Contracts"
Cohesion: 0.05
Nodes (37): decodeAirQuality, decodeEnvironment, decodeFilterCounters, decodeSystemStatus, DocasaCodec, encodeAirQuality, encodeEnvironment, encodeFilterCounters (+29 more)

### Community 3 - "Apple Icon Asset Catalogs"
Cohesion: 0.06
Nodes (15): Cocoa, Flutter, flutter_blue_plus_darwin, flutter_local_notifications, FlutterMacOS, Foundation, AppDelegate, SceneDelegate (+7 more)

### Community 4 - "Settings Column Types"
Cohesion: 0.06
Nodes (32): AppSettings, batteryPct, batteryV, charging, fanRpm, FilterEvents, HourAggregates, hourStartMs (+24 more)

### Community 5 - "BLE Connection Layer"
Cohesion: 0.06
Nodes (30): connect, disconnect, dispose, DocasaConnection, readDeviceInfo, readFilterCounters, resetFilter, states (+22 more)

### Community 6 - "Fake BLE Telemetry Generator"
Cohesion: 0.06
Nodes (29): 5, air, _battery, _charging, _chargingLeft, counters, elapsed, env (+21 more)

### Community 7 - "Air Quality Models"
Cohesion: 0.06
Nodes (31): air, AirQualitySample, at, batteryFull, batteryPct, batteryVoltage, charging, complete (+23 more)

### Community 8 - "GTK Flutter Embedder"
Cohesion: 0.09
Nodes (14): fl_register_plugins(), main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line() (+6 more)

### Community 9 - "App Data Services"
Cohesion: 0.08
Nodes (21): FilterSettings, DocasaTelemetry, alertPortProvider, build, bump, c, computeFilterHealth, counters (+13 more)

### Community 10 - "Core Data Layer Imports"
Cohesion: 0.07
Nodes (21): connect, day, db, disconnect, dispose, emit, floorMin, hour (+13 more)

### Community 11 - "Package Dependencies"
Cohesion: 0.07
Nodes (26): dependencies, cupertino_icons, drift, fl_chart, flutter, flutter_blue_plus, flutter_local_notifications, flutter_riverpod (+18 more)

### Community 12 - "History Repository UI Data"
Cohesion: 0.09
Nodes (20): HistoryMetric, HistoryRange, FilterPage, _axisStyle, build, _chart, color, createState (+12 more)

### Community 13 - "Windows Runner C++ Core"
Cohesion: 0.12
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 14 - "History Bucketing Types"
Cohesion: 0.09
Nodes (19): bucketCount, bucketMs, column, coverage, _floor, HistoryRepository, HistorySeries, isEmpty (+11 more)

### Community 15 - "Linux Desktop Build"
Cohesion: 0.10
Nodes (22): APPLICATION_ID com.example.docasa_app (GTK app identifier), APPLY_STANDARD_SETTINGS (Linux: cxx_std_14, -Wall -Werror, -O3+NDEBUG outside Debug), BINARY_NAME docasa_app (Linux executable name), Linux Bundle Install (relocatable bundle under build dir; AOT lib installed only for non-Debug), linux/CMakeLists.txt (Linux desktop build config, CMake 3.13, project runner, C++14, GTK3 via pkg-config), flutter_assemble target (linux/flutter/CMakeLists.txt: tool_backend.sh, ephemeral libflutter_linux_gtk.so, icudtl.dat, libapp.so AOT), GTK/GLIB/GIO pkg-config dependencies (Flutter Linux embedder), Linux Runner Executable (main.cc, my_application.cc, generated_plugin_registrant.cc; links flutter + PkgConfig::GTK) (+14 more)

### Community 16 - "Web Favicon Assets"
Cohesion: 0.10
Nodes (20): Flutter default launcher icon (template branding asset), Web Favicon (favicon.png, 16x16 8-bit RGBA browser icon), Browser Tab Icon Role (rel=icon link target declared in web/index.html), Icon artwork: likely stock Flutter logo favicon from flutter create template (visual content unverified, vision unavailable), Icon-192.png - PWA app icon, 192x192 8-bit RGB PNG (visual content unverified), Icon-512.png - PWA app icon, 512x512 8-bit RGB PNG (visual content unverified), App Brand Logo (icon visual content, unverified), PWA Icon Family (web/icons: Icon-192, Icon-512, maskable variants, manifest-listed) (+12 more)

### Community 17 - "Filter Health Engine"
Cohesion: 0.10
Nodes (17): computeFilterHealth, consumed, estimateLoadRatePerDay, FilterHealth, hourBudgetRpmS, hourFrac, loadBinding, loadBudgetRpmUgS (+9 more)

### Community 18 - "BLE Telemetry Streams"
Cohesion: 0.11
Nodes (12): _buffer, _db, flush, _flushInterval, _flushRows, _flushTimer, _onTelemetry, _recorded (+4 more)

### Community 19 - "Ponytail Audit Skills"
Cohesion: 0.11
Nodes (19): Audit Evidence Rules (concrete failure case required; grep tree incl. tests/fixtures/config before calling code unused; shortcut: comment is a decision not a finding unless load crosses it), Audit Finding Categories (bug, risk/security+data loss, scale/load, missing test, speed, lean), ponytail-audit Skill (whole-repo quality audit, ranked, one-shot), Debt Ledger Row (file:line, what was simplified, ceiling, upgrade trigger; no-trigger rows flagged as rot risk), ponytail-debt Skill (harvest shortcut: comments into one debt ledger), Ponytail Benchmark Figures (Opus 5.5, 39 tasks x 5 runs, 18 with hidden checks; LOC 47%, output tokens 55%, cost 74%, time 59%; hidden checks 97% vs 96%; tests where logic needs one 98% vs 68%), Ponytail Honesty Boundary (benchmark averages only; never invent per-repo savings; real per-repo figures come from /ponytail-debt), ponytail-gain Skill (measured-impact scoreboard, one-shot display) (+11 more)

### Community 20 - "Win32 Window Bracing"
Cohesion: 0.16
Nodes (6): EnableNonClientDpiScaling, Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 21 - "Recording Service"
Cohesion: 0.11
Nodes (15): _alerts, _alertTimer, compactor, _compactTimer, _db, _defaultNow, dispose, _evaluateAlerts (+7 more)

### Community 22 - "Windows Flutter Shell"
Cohesion: 0.12
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 23 - "Number Formatting"
Cohesion: 0.11
Nodes (17): bigInt, coveragePct, _d1, date, dateTime, daysFromNow, fanSecondsAsHours, Fmt (+9 more)

### Community 24 - "Riverpod Feature Pages"
Cohesion: 0.13
Nodes (10): _body, AppShell, _AppShellState, build, createState, initState, main, _pages (+2 more)

### Community 25 - "Filter Budget Dashboard"
Cohesion: 0.13
Nodes (12): _budgetCard, _countersCard, createState, dispose, _healthCard, _healthColor, _hourCtrl, initState (+4 more)

### Community 26 - "Filter Budget Settings"
Cohesion: 0.12
Nodes (14): FilterBudgets, alertThresholdPct, budgets, copyWith, _db, _kHourBudget, _kLastAlert, _kLoadBudget (+6 more)

### Community 27 - "Shared App Imports"
Cohesion: 0.12
Nodes (3): main, _now, t

### Community 28 - "Dashboard Widgets"
Cohesion: 0.23
Nodes (13): build, DashboardPage, SystemPage, build, DevicePage, build, _FilterPageState, connectionStateProvider (+5 more)

### Community 29 - "Reusable UI Widgets"
Cohesion: 0.14
Nodes (11): build, color, icon, label, pm25, stage, state, subtitle (+3 more)

### Community 30 - "Drift Settings Data Classes"
Cohesion: 0.26
Nodes (10): AppSetting, AppSettingsCompanion, FilterEvent, FilterEventsCompanion, HourAggregate, HourAggregatesCompanion, MinuteAggregate, MinuteAggregatesCompanion (+2 more)

### Community 31 - "Air Stage Models"
Cohesion: 0.17
Nodes (10): AirStage, batteryPct, clamped, color, DomainClamps, fanRpm, fromIndex, index1 (+2 more)

### Community 32 - "macOS App Icon Set"
Cohesion: 0.18
Nodes (12): macOS App Icon 1024px (app_icon_1024.png), macOS App Icon 128x128 @1x (app_icon_128.png, PNG 128x128 8-bit RGBA), AppIcon.appiconset macOS Asset Set (10 catalog entries, 16-1024px, 1x/2x), Docasa App Visual Identity (icon artwork content), macOS App Icon 16px (app_icon_16.png), macOS App Icon 256px (app_icon_256.png), macOS App Icon 32px (app_icon_32.png), macOS App Icon 512px (app_icon_512.png) (+4 more)

### Community 34 - "BLE Protocol Governance"
Cohesion: 0.20
Nodes (11): App Connect Handshake, BLE Protocol Contract v1.0, Golden Test Fixtures F1-F7 / X1-X6, Single Central Connection Policy, D-002: BLE UUIDs Frozen (d0ca5a prefix), D-012: App History Retention Policy, Definition of Done (section 10.4), Phase-Gated Lifecycle (Phases 0-6) (+3 more)

### Community 35 - "macOS Icon Densities"
Cohesion: 0.18
Nodes (11): App Icon 1024px (macOS Runner density variant, 512x512@2x), App Icon 128px (macOS Runner density variant, 128x128@1x), App Icon 16px (macOS Runner density variant, 16x16@1x), App Icon 256px (macOS Runner, 256x256@1x and 128x128@2x), Docasa App Icon Artwork (visual content unverified - vision unavailable), App Icon 32px (macOS Runner density variant, 32x32@1x and 16x16@2x), App Icon 512px (macOS Runner density variant, 512x512@1x and 256x256@2x), App Icon 64px (macOS Runner density variant, 32x32@2x) (+3 more)

### Community 36 - "Widget Test Imports"
Cohesion: 0.20
Nodes (5): main, budgets, counters, main, now

### Community 37 - "Win32 Window Handler"
Cohesion: 0.24
Nodes (4): Win32Window, child_content_, quit_on_close_, window_handle_

### Community 38 - "BLE Characteristics Map"
Cohesion: 0.22
Nodes (10): Command Characteristic (write), Environment Characteristic (JSON v1), Filter Counters Characteristic (read-only), JSON v1 Payload Format, System Status Characteristic (JSON v1), DOCASA Telemetry Service (d0ca5a0e-...), D-004: uint64 NVS Counter Design, D-010: Write Command Security (pending) (+2 more)

### Community 40 - "Fake Generator Imports"
Cohesion: 0.22
Nodes (4): _chunk, HistorySeeder, _insert, seed

### Community 41 - "Persistence Gate Plans"
Cohesion: 0.28
Nodes (9): Gate G1: Persistence and Behavior Checks, D-011: Filter Budgets and Preset Models (pending), Firmware Behavior-Preservation Gate (section 10.2), Filter Lifetime Tracking Model, NVS Raw Counter Persistence Design, v3 Firmware Baseline Architecture, Frozen v3 Baseline (Diff Target), firmware-diff-check.sh Gate Tool (+1 more)

### Community 42 - "Architecture Decisions"
Cohesion: 0.25
Nodes (8): D-007: App State Management - Riverpod, D-008: App Local DB - Drift (SQLite), D-009: Android minSdk Decision, D-013: Phase-0 Toolchain Pins, D-016: Phase 3 Dependency Pins and Retention, Environment Facts and Project State (section 11), Phase 3 Gotchas Register, Gate Report G0: Foundations PASS

### Community 43 - "App Theme Colors"
Cohesion: 0.25
Nodes (5): accent, cardBg, dark, DocasaTheme, scaffoldBg

### Community 44 - "Win32 Point Geometry"
Cohesion: 0.21
Nodes (6): Point, x, y, Size, height, width

### Community 45 - "iOS Runner Shell"
Cohesion: 0.38
Nodes (7): Docasa iOS Runner App (Flutter iOS shell), AppIcon.appiconset (iOS app icon asset set), iOS App Icon 20x20@2x (40x40 PNG, unmodified Flutter default logo), App Icon (Docasa mobile app visual identity), Flutter SDK Default App Icon (template artwork), Docasa iOS App Icon 40x40@1x (iPad), Flutter default placeholder app icon

### Community 46 - "Analyzer Lint Config"
Cohesion: 0.33
Nodes (5): analyzer, exclude, include, linter, rules

### Community 47 - "Bench Gate G2 Plan"
Cohesion: 0.33
Nodes (6): Gate G2: BLE Telemetry via nRF Connect, Bench Runbook: Flashing and G1/G2 Verification, Air Quality Characteristic (JSON v1), D-005: Working Firmware v4 and Version Scheme, D-015: Phases 1+2 Merged into v4.1.0, pm10Value Naming Trap (holds PM1.0)

### Community 48 - "Development Governance Doc"
Cohesion: 0.33
Nodes (5): Document Governance Model, Development Process (Living Governance Doc), Phased Roadmap P0-P5, IoT Integration Plan v1 (Architecture Authority), IoT Integration Feature Prompt

### Community 50 - "Required Feature List"
Cohesion: 0.60
Nodes (5): Required App Feature List, Requirement 3: Filter Health Monitoring and Replacement Alerts, Requirement 2: Day/Week/Month Air-Quality History, Requirement 1: Realtime AQ Readings and System Status, Requirement Traceability Matrix (Plan section 10)

### Community 51 - "iOS Launch Images"
Cohesion: 0.40
Nodes (4): iOS launch screen placeholder visual (LaunchImage asset), Blank transparent 1x1 placeholder pixel (inferred visual content of Flutter template launch image, unverified), LaunchImage@3x.png (iOS launch screen image, 3x density variant, 1x1 8-bit gray+alpha PNG), LaunchImage asset set (iOS launch screen image registered in Contents.json with 1x/2x/3x density variants)

### Community 52 - "App Widget Companions"
Cohesion: 0.40
Nodes (4): ConnectionChip, StageHero, ValueTile, DocasaApp

### Community 53 - "Android Launcher Icons"
Cohesion: 0.67
Nodes (4): Docasa App Launcher Icon (xhdpi density), Docasa App Launcher Icon (ic_launcher, xxxhdpi, 192x192, 8-bit palette PNG; pixel content not visually verified), Docasa App Visual Identity, Android Launcher Icon Density Family (ic_launcher across mipmap mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi)

### Community 54 - "iOS Icon Density Slots"
Cohesion: 0.50
Nodes (4): iOS App Icon 20x20@1x (iPad 20pt @1x slot) - default Flutter logo, AppIcon.appiconset - iOS icon family (iPhone/iPad/marketing size variants), Flutter default logo icon design (Flutter blues #54C5F8 / #01579B on white), Flutter iOS Runner host app (docasa-app)

### Community 55 - "iOS Icon Variants"
Cohesion: 0.67
Nodes (4): iOS App Icon 60x60@3x (180x180 px, blue Flutter-logo mark on white), AppIcon.appiconset (iOS icon asset set, 16 size variants), Docasa App (iOS bundle, CFBundleDisplayName 'Docasa App'), Stock Flutter Template Icon Artwork (Flutter logo blues #54C5F8/#29B6F6/#01579B on white)

### Community 56 - "PWA Maskable Icons"
Cohesion: 0.50
Nodes (4): Icon-maskable-512.png (512x512 8-bit RGBA PNG, PWA maskable app icon), Icon-maskable-512 Depicted Artwork (visual content unverified - vision unavailable), Docasa PWA Icon Asset Family (web/icons: Icon-192, Icon-512, Icon-maskable-192, Icon-maskable-512), PWA Maskable Icon Format (safe-zone adaptive icon)

### Community 59 - "Android Icon Asset Family"
Cohesion: 0.67
Nodes (3): App Launcher Visual Identity (ic_launcher asset), ic_launcher.png (mdpi launcher icon, 48x48), Android Launcher Icon Density Set

### Community 60 - "iOS Icon Asset Sizes"
Cohesion: 0.67
Nodes (3): AppIcon.appiconset (iOS asset catalog icon set), Docasa App (docasa_app, Flutter iOS build target branding), iOS App Icon 40x40@2x (Docasa, 80x80px Spotlight/Settings slot)

### Community 61 - "iOS Placeholder Icons"
Cohesion: 0.67
Nodes (3): iOS App Icon 40x40@3x (120px PNG, iPhone slot), AppIcon Asset Set (iOS icon family), Default Flutter Placeholder Branding (light gray background, teal/blue glyph)

### Community 62 - "iPad Icon Slots"
Cohesion: 0.67
Nodes (3): iOS App Icon 76x76@1x (iPad), AppIcon Asset Set (iOS Runner asset catalog icon family), Icon artwork: likely stock Flutter logo (white background, Material light blue palette)

### Community 63 - "iPad Pro Icon Slot"
Cohesion: 0.67
Nodes (3): iOS App Icon 83.5x83.5@2x (iPad, Runner), AppIcon Asset Set (iOS Runner), Icon artwork (visual content unverified, vision unavailable; 167x167 8-bit colormap PNG)

### Community 64 - "Launch Image Placeholder"
Cohesion: 0.67
Nodes (3): LaunchImage.png (iOS launch image asset, 1x1 placeholder), iOS Launch Screen Image Concept, Transparent Placeholder Pixel Concept

### Community 65 - "macOS Icon Catalog"
Cohesion: 0.67
Nodes (3): macOS AppIcon asset set (multi-density icon variants 16-1024px + Contents.json manifest), macOS App Icon 1024x1024 PNG (AppIcon.appiconset, 512x512 @2x master variant), App icon visual content (unverified - vision unavailable in this run)

### Community 66 - "PWA Web Icons"
Cohesion: 0.67
Nodes (3): PWA Maskable App Icon 192x192 (web/icons), Icon artwork (visual content unverified, vision unavailable; 192x192 8-bit RGBA PNG, maskable safe-zone), PWA Icon Set (web/manifest.json icons: Icon-192, Icon-512, Icon-maskable-192, Icon-maskable-512; this asset purpose=maskable)

## Ambiguous Edges - Review These
- `Docasa App Launcher Icon (ic_launcher, xxxhdpi, 192x192, 8-bit palette PNG; pixel content not visually verified)` → `Docasa App Visual Identity`  [AMBIGUOUS]
  android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png · relation: conceptually_related_to
- `Docasa iOS App Icon 40x40@1x (iPad)` → `Flutter default placeholder app icon`  [AMBIGUOUS]
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png · relation: conceptually_related_to
- `iOS App Icon 83.5x83.5@2x (iPad, Runner)` → `Icon artwork (visual content unverified, vision unavailable; 167x167 8-bit colormap PNG)`  [AMBIGUOUS]
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png · relation: conceptually_related_to
- `LaunchImage.png (iOS launch image asset, 1x1 placeholder)` → `Transparent Placeholder Pixel Concept`  [AMBIGUOUS]
  ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png · relation: references
- `LaunchImage@2x.png` → `iOS launch screen placeholder visual (LaunchImage asset)`  [AMBIGUOUS]
  ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png · relation: implements
- `LaunchImage@3x.png (iOS launch screen image, 3x density variant, 1x1 8-bit gray+alpha PNG)` → `Blank transparent 1x1 placeholder pixel (inferred visual content of Flutter template launch image, unverified)`  [AMBIGUOUS]
  ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png · relation: conceptually_related_to
- `macOS App Icon 1024x1024 PNG (AppIcon.appiconset, 512x512 @2x master variant)` → `App icon visual content (unverified - vision unavailable in this run)`  [AMBIGUOUS]
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png · relation: conceptually_related_to
- `macOS App Icon 128x128 @1x (app_icon_128.png, PNG 128x128 8-bit RGBA)` → `Docasa App Visual Identity (icon artwork content)`  [AMBIGUOUS]
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png · relation: conceptually_related_to
- `macOS App Icon 16px (app_icon_16.png)` → `macOS App Icon 1024px (app_icon_1024.png)`  [AMBIGUOUS]
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png · relation: conceptually_related_to
- `macOS App Icon 512px (app_icon_512.png)` → `Visual content of app_icon_512.png (unverified - vision unavailable)`  [AMBIGUOUS]
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png · relation: conceptually_related_to
- `App Icon 256px (macOS Runner, 256x256@1x and 128x128@2x)` → `Docasa App Icon Artwork (visual content unverified - vision unavailable)`  [AMBIGUOUS]
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png · relation: conceptually_related_to
- `App Icon 64px (macOS Runner density variant, 32x32@2x)` → `Flutter Default macOS Template Icon (possible unverified artwork)`  [AMBIGUOUS]
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png · relation: implements
- `Web Favicon (favicon.png, 16x16 8-bit RGBA browser icon)` → `Icon artwork: likely stock Flutter logo favicon from flutter create template (visual content unverified, vision unavailable)`  [AMBIGUOUS]
  web/favicon.png · relation: conceptually_related_to
- `Icon-192.png - PWA app icon, 192x192 8-bit RGB PNG (visual content unverified)` → `Flutter default launcher icon (template branding asset)`  [AMBIGUOUS]
  web/icons/Icon-192.png · relation: conceptually_related_to
- `Icon-512.png - PWA app icon, 512x512 8-bit RGB PNG (visual content unverified)` → `App Brand Logo (icon visual content, unverified)`  [AMBIGUOUS]
  web/icons/Icon-512.png · relation: conceptually_related_to
- `PWA Maskable App Icon 192x192 (web/icons)` → `Icon artwork (visual content unverified, vision unavailable; 192x192 8-bit RGBA PNG, maskable safe-zone)`  [AMBIGUOUS]
  web/icons/Icon-maskable-192.png · relation: conceptually_related_to
- `Icon-maskable-512.png (512x512 8-bit RGBA PNG, PWA maskable app icon)` → `Icon-maskable-512 Depicted Artwork (visual content unverified - vision unavailable)`  [AMBIGUOUS]
  web/icons/Icon-maskable-512.png · relation: references

## Knowledge Gaps
- **507 isolated node(s):** `states`, `telemetry`, `readDeviceInfo`, `readFilterCounters`, `syncTime` (+502 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 667 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **32 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AppDatabase` connect `Drift Database Definition` to `Drift Column Schema`, `App Data Services`, `Core Data Layer Imports`, `BLE Telemetry Streams`, `Recording Service`, `Filter Budget Settings`?**
  _High betweenness centrality (0.057) - this node is a cross-community bridge._
- **What connects `states`, `telemetry`, `readDeviceInfo` to the rest of the system?**
  _507 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Drift Column Schema` be split into smaller, more focused modules?**
  _Cohesion score 0.041536050156739814 - nodes in this community are weakly interconnected._
- **Why does `DocasaConnectionState` connect `Reusable UI Widgets` to `App Data Services`, `BLE Connection Layer`, `Air Quality Models`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Should `Database Persistence Layer` be split into smaller, more focused modules?**
  _Cohesion score 0.044326241134751775 - nodes in this community are weakly interconnected._

### Low-confidence Hints
_AMBIGUOUS edges — the extractor was unsure. Verify before acting on these._

- **What is the exact relationship between `Docasa App Launcher Icon (ic_launcher, xxxhdpi, 192x192, 8-bit palette PNG; pixel content not visually verified)` and `Docasa App Visual Identity`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Docasa iOS App Icon 40x40@1x (iPad)` and `Flutter default placeholder app icon`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._