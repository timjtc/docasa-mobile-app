# DOCASA — IoT Integration Plan (ESP32 ↔ Mobile App)

Status: planning draft
Scope: device-to-app connectivity over Bluetooth Low Energy (BLE). WiFi/cloud is noted as a future phase only.
**Firmware change constraint (hard):** ESP32 code changes are limited to (1) BLE capability, (2) NVS/data persistence, and (3) data transmission to the app. **No hardware-control or operation code may be changed** — see §1.4.
Source firmware: `Air_Purifier_Final_Revision_pt2.ino` → current revision `docasa-air-purifier-v3.ino` (4-pin ARCTIC P8 Max fan).

---

## 1. Firmware Baseline Analysis

### 1.1 Current architecture

Two firmware revisions exist in this repo: `Air_Purifier_Final_Revision_pt2.ino` (previous baseline) and **`docasa-air-purifier-v3.ino` (active baseline**, 634 lines, includes the 4-pin fan rework). Same monolithic, non-blocking structure in both:

```
loop() @ ~15ms: readSensorsAsync() → calculateCompositeAQI() → updateFan()
                → updateLEDs() → handleDisplayTransitions() → updateDisplay()
                → updateAndDrawParticles() → delay(15)
```

Hardware in play (v3):

| Peripheral | Interface | Pins | Notes |
|---|---|---|---|
| ST7789 TFT 240×320 | SPI | 15 (CS), 2 (DC), 4 (RST) | Two auto-cycling pages, particle animation |
| PMS7003 (PM sensor) | UART2 @ 9600 | 16 (RX), 17 (TX) | Reports ≈ 1 Hz internally |
| BME680 (temp/hum/VOC) | I²C @ 0x77 | default Wire (SDA 21, SCL 22) | Forced-mode, async reads |
| WS2812B LED strip (30) | FastLED I2S driver | 13 | Status color per AQI stage |
| Fan (ARCTIC P8 Max, 4-pin) | PWM via transistor (LEDC, 25 kHz, 8-bit) | 27 | ✅ handled in v3: `FAN_PWM_FREQ 25000`, inverse duty (255 = fan OFF; details §9.2) — **do not modify further** (§1.4) |
| Battery sense (4S Li-ion) | ADC1 | 33 | Calibrated multiplier, 32× oversampling, EMA smoothing |
| Charge status | digital in | 14 | + "truly full" detection (≥16.31 V held 5 min) |

Framework note: the sketch uses `ledcAttach(pin, freq, res)` — the **ESP32 Arduino core 3.x API**. Library versions chosen later must match core 3.x.

### 1.2 Data inventory (what the LCD shows = what the app must be able to query)

**Page 0 — AIR MONITOR**

| Value | Source variable | Unit | Notes |
|---|---|---|---|
| PM2.5 | `pm25Value` | µg/m³ | `data.pm25_env` |
| PM1.0 | `pm10Value` | µg/m³ | ⚠️ misleadingly named `pm10Value` but holds PM1.0 (`data.pm10_env`). **No rename** — BLE code must read the v3 name as-is (§1.4) |
| PM10 | `pm100Value` | µg/m³ | `data.pm100_env` |
| Air status | `overallStage` | stage 1–5 | GOOD/FAIR/POOR/BAD/HAZARD; composite of PM2.5 + PM10 threshold stages, bumped +1 when `gasResistance < 30 kΩ` |

**Page 1 — SYSTEM STATUS**

| Value | Source variable | Unit | Notes |
|---|---|---|---|
| Temperature | `temperature` | °C | Intake-side ambient |
| Humidity | `humidity` | % RH | Intake-side ambient |
| VOC | `gasResistance` | kΩ | BME680 raw gas resistance proxy; **not** calibrated ppb (see §7.10) |
| Fan speed | `currentFanRpm` | RPM | v3: commanded target RPM (0/1000/2000/3000/4000 by stage), LCD row "FAN SPEED (RPM)" |
| Battery | `batteryPct` | % | EMA-smoothed from voltage |
| Charging | `isCharging` | bool | |
| Battery full | `isTrulyFull` | bool | |
| Battery voltage | `smoothedVoltage` | V | Not shown but trivially available; useful for analytics |
| Fan RPM (measured) | — | RPM | Not yet available: v3 has no tach wiring — the LCD RPM figure is the commanded target. Measured RPM arrives only via §9.3, which is **outside the firmware change scope** (§1.4) |

**Internal, needed for the app features**

| Value | Where it lives | Notes |
|---|---|---|
| Uptime | `millis()` | Rolls over at ~49.7 days (§7.2) |
| Firmware version | none | Must be added (OTA/diagnostics depend on it) |
| Filter counters | none | To be created (§4) |

### 1.3 Gaps that block the IoT feature

1. **No radio code at all** — no BLE/WiFi initialization, stack, or data model.
2. **No persistent storage** — nothing survives power cycles. Required for filter counters (§4).
3. **No wall-clock source** — only `millis()`. Device cannot know calendar time while unpowered; time must come from the app (§5).
4. **Monolithic structure** — everything global. §1.4 forbids restructuring; BLE/persistence additions are appended into the same `.ino` instead.
5. **Blocking boot screen** — `setup()` spends 5 s in `showBootScreen()`; decide whether BLE comes up before or during it (§7.6).
6. **Update cadence mismatch** — loop runs at ~66 Hz; BLE notify must be decimated (§3.3).

### 1.4 Firmware change scope (hard constraint)

**Only three kinds of ESP32 changes are permitted:**
1. **BLE capability** — stack init, GATT server, security/bonding, transmission to the app.
2. **NVS / data persistence** — raw filter/lifecycle counters (§4.2).
3. **Data transmission** — exposing existing values; app-side analytics (§4).

Everything else is **frozen**, including `setup()` hardware init, `updateFan()`, `updateLEDs()`, `handleDisplayTransitions()`, sensor-read logic, and display/animation behavior. Consequences:

- BLE is added **observationally**: new code reads existing global variables and mirrors them; it must not alter sensor/fan/display logic, loop timing (`delay(15)`), or sequence.
- Integration into `loop()` is additive only (a 1 Hz notify scheduler call and a counter-accumulation helper) — both are passthrough/data code, not control code.
- **Out of scope (dropped from earlier plan versions):** fan override command (would require `fanMode`/manual-RPM logic inside `updateFan()`), tach wiring/PCNT read (new hardware code, §9.3), any duty/polarity edits. These move to a "restricted" future list, unlockable only if the constraint is later relaxed.
- Mechanical, zero-behavior renames (e.g. `pm10Value` → `pm1Value`) and module-splitting are allowed only with explicit approval and only if they provably compile identically; default approach is to touch nothing.

---

## 2. Connectivity Options & Tradeoffs

| Option | Verdict | Why |
|---|---|---|
| **A. BLE GATT server (ESP32 peripheral, custom service)** | ✅ **Primary choice** | No infrastructure (no router/account needed), phone-native APIs, low power, works out-of-range-free (proximity control), enough throughput for 1 Hz telemetry. |
| B. Nordic UART Service (NUS) emulation | Acceptable prototype shortcut | Fastest to build (treat BLE as a serial pipe), but one giant JSON pipe fights GATT idioms and complicates permissions/notifications granularity. Consider for a 1-week throwaway spike, not the product. |
| C. WiFi + HTTP/MQTT only | ❌ as primary | Setup friction (provisioning, credentials, no router = no connection), higher power draw, server needed. |
| D. Dual radio (BLE + WiFi) | 🕐 Future phase | BLE for proximity control/telemetry; WiFi later for OTA firmware updates, cloud sync, history upload (§8, P4). ESP32 has both radios; coexistence is supported. |

Decision: **Option A now, C/D deferred.** This keeps the MVP free of cloud commitments while the app-side analytics layer is designed to later talk to a cloud backend without re-plumbing the device.

---

## 3. Proposed BLE Architecture

### 3.1 Stack choice

| Library | Pros | Cons | Verdict |
|---|---|---|---|
| **NimBLE-Arduino** (v2.x) | ~50% less flash & RAM than Bluedroid, actively maintained, core 3.x compatible, clean async callbacks | Separate dependency | ✅ **Use this** |
| Bluedroid (built-in `BLEDevice.h`) | Ships with the core | Heavier, worse-documented notify behavior | Fallback |
| ESP-IDF native | Max control | abandons Arduino framework | No |

Note: verify NimBLE-Arduino 2.x against the exact core 3.x minor version installed in the toolchain.

### 3.2 GATT design

ESP32 = peripheral (GATT server). Phone = central. Single connection (one central at a time — see §7.9).

Standard services first:
- **Device Information Service** (0x180A): manufacturer, model, firmware/hardware revision → free OTA/diagnostics groundwork.
- **Battery Service** (0x180F / 0x2A19): phones render battery % natively. Charging/full state needs the custom characteristic anyway.

Custom service (example UUIDs below are placeholders — **generate fresh random 128-bit UUIDs before implementation**; suggested prefix `d0ca5a…` for readability):

| Characteristic | Example UUID (regenerate) | Props | Source | Cadence |
|---|---|---|---|---|
| Air Quality | `d0ca5a01-…` | read, notify | pm1.0, pm2.5, pm10, stage | 1 Hz |
| Environment | `d0ca5a02-…` | read, notify | temp, humidity, gas kΩ | 1 Hz |
| System Status | `d0ca5a03-…` | read, notify | fan %, batt %, charging, full, batt V | 1 Hz + on-change |
| Filter Counters | `d0ca5a04-…` | read | §4 raw counters | on read (app polls) |
| Command | `d0ca5a05-…` | write | filter reset, time sync (fan override **excluded** — §1.4) | on write |

Design rules:
- **Separate characteristics per domain** (vs. one mega-characteristic) so the app can subscribe selectively and MTU is never a constraint.
- **Notify, don't indicate** (no per-notification ACK overhead); commands use write-with-response.
- MTU negotiation target ≥ 247 (ESP32/NimBLE supports up to 512). JSON payloads here stay < ~120 B, so no chunking needed at this scale.
- **Advertising identity (decide before P1, must be frozen in code + app):** advertised local name (suggested: `DOCASA-AirPurifier`) and the custom service UUID included in the advertising payload so the app can filter devices by service UUID instead of name-matching alone.

### 3.3 Realtime strategy

- Sensors natively report ≈ 1 Hz (PMS7003) / 1–2 Hz effective (BME680 forced mode) — a **1 Hz notify rate loses no information** while the loop runs at ~66 Hz. Implement a 1 Hz scheduler in `loop()`, not timers in BLE callbacks.
- **On-change** extra notifies: `overallStage`, `isCharging`, `isTrulyFull` (event-like values shouldn't wait for the next tick).
- BLE callbacks must never call `FastLED.show()` or TFT draws; they only set flags/push into small ring buffers consumed by `loop()`.

### 3.4 Payload encoding

| Encoding | Pros | Cons | Verdict |
|---|---|---|---|
| **JSON + version field** | Human-readable (nRF Connect debugging), trivial to parse in any app stack, fastest to ship | Larger (~10× binary), text parsing cost | ✅ **v1 of the protocol** |
| Binary packed struct | Tiny (16–24 B), fast, stable | Schema discipline needed, harder to debug, version migration pain | Adopt later only if throughput demands |
| CBOR | Middle ground | Extra dependency on both sides | Skip for now |

Version byte/field is mandatory in all schemes (`"v":1`) — the only realistic firmware↔app upgrade path without breaking old installs.

Example payloads:

```json
{"v":1,"pm1":14,"pm25":8,"pm10":21,"st":2}
{"v":1,"t":24.6,"h":47.2,"voc":38.4}
{"v":1,"fan":3000,"bat":84,"chg":0,"full":0,"vb":15.31}   // "fan" = commanded target RPM (v3); becomes measured RPM if tach is ever wired (§9.3)
{"v":1,"fs":10800000,"pwfs":74250000,"on":3210,"rt":2980}
```

Key dictionary (shared contract for the codec on both sides):

| Key | Type | Unit | Device source |
|---|---|---|---|
| `v` | int | — | Protocol version, constant 1 |
| `pm1` | int | µg/m³ | `pm10Value` (v3 name; actually PM1.0) |
| `pm25` | int | µg/m³ | `pm25Value` |
| `pm10` | int | µg/m³ | `pm100Value` |
| `st` | int | 1–5 | `overallStage` |
| `t` | float | °C | `temperature` |
| `h` | float | % RH | `humidity` |
| `voc` | float | kΩ | `gasResistance` |
| `fan` | int | RPM | `currentFanRpm` (commanded target) |
| `bat` | int | % | `batteryPct` |
| `chg` | 0/1 | — | `isCharging` |
| `full` | 0/1 | — | `isTrulyFull` |
| `vb` | float | V | `smoothedVoltage` |
| `fs` | uint32 | RPM·s | NVS `fanSeconds` |
| `pwfs` | uint64 | RPM·µg·s | NVS `pmWeightedFanSeconds` |
| `on` / `rt` | uint32 | h | NVS `powerOnHours` / `runtimeHours` |

Commands (phone → device, all JSON v1):

```json
{"cmd":"resetFilter"}                     // after physical filter replacement (persistence mgmt — within scope)
{"cmd":"time","epoch":1769472000}         // re-sent on every app connect (§5)
```

**Deferred (not in v1 protocol, per §1.4):** `{"cmd":"fan",...}` — fan override requires modifying `updateFan()` control logic, which is out of scope. If the constraint is ever relaxed, the command should be RPM-based (v3 targets: 0/1000/2000/3000/4000).

---

## 4. Filter Lifetime Tracking

**Architecture principle (agreed): device stores raw data only; all computation/analytics lives in the mobile app.**

### 4.1 What the sensors can and cannot tell us

The sensors sit on the **intake (unfiltered) side** — there is no downstream measurement, so filter *effectiveness* is not directly measurable today. But the intake air *is* what the filter ingests, so a usage/load model is legitimately computable from unfiltered-air data alone. This is how most commercial purifiers (Dyson, Philips, etc.) compute filter life without downstream sensing.

- ✅ Possible now: **load-weighted usage model** (§4.2), plus app-side decay-curve analytics (§4.4). The 4-pin fan's tach wire adds real airflow signal once wired (§9.3 — currently deferred under the §1.4 scope).
- ❌ Not possible now: direct clogging measurement (needs hardware: differential pressure sensor or outlet PM sensor — future roadmap, §8 P5). A fan tach is *now available* with the 4-pin fan, but it measures airflow indirectly and cannot see pressure rise from clogging on its own.

### 4.2 Raw counters persisted on-device (NVS)

Implementation: `Preferences` (NVS wrapper), namespace `"docasa"`. Written every **5 minutes** (throttle) — no graceful shutdown exists on a battery device, so ≤ 5 min of accumulation is lost per power-off. Flash-wear math: 12 writes/h ≈ 105 k appends/yr; NVS pages take ~126 appends before an erase and are wear-leveled → well under 1% of the ~100 k erase endurance per year. Safe.

| Counter | Type | Definition | App uses it for |
|---|---|---|---|
| `fanSeconds` | uint32 | Σ fanInput × dt (v3: commanded target RPM, so RPM·s; app normalizes) | Baseline health: hours-at-speed |
| `pmWeightedFanSeconds` | uint64 | Σ fanInput × PM2.5 × dt (load integral; same unit basis as above) | Dirty-air weighting — filter consumes faster in bad air |
| `runtimeHours` | uint32 | Σ dt while powered | Firmware diagnostics |
| `powerOnHours` | uint32 | Σ dt while powered | Same (may merge with above) |

⚠️ **Overflow trap:** `pmWeightedFanSeconds` as uint32 is hopeless even with RPM-basis input (3000 RPM × PM50 = 150,000 units/s → breaches 4.29 × 10⁹ within ~8 h of full-speed dirty-air runtime… i.e., within days of real use). **uint64 storage is mandatory** (or accumulate in RPM·µg·min units). Decide before implementing.

⚠️ **`millis()` rollover at 49.7 days:** always accumulate via unsigned delta (`now - last`), never absolute `millis()` comparisons. This is the classic ESP32 timer bug.

Filter health is **not** stored or computed on-device. App-side:

```
health% = 1 − (pmWeightedFanSeconds / loadBudget)      // primary signal
health% = min(health%, 1 − fanSeconds / hourBudget)    // secondary cap (pure-hours)
remainingDays = f(health trend, recent usage rate)
```

`loadBudget`/`hourBudget` are **app-side configuration** (settable per filter model, e.g. 3000 h nominal); the device stays filter-model-agnostic. `resetFilter` zeroes both integrals via the Command characteristic (security-gated, §7.8).

### 4.3 What the app builds on top

- Filter life %, projected replacement date (needs time, §5).
- "Filter consumed faster than expected" explanations from PM history (ties into §4.4).
- Replacement reminders (local notifications), reset flow with confirmation.
- Quality-of-estimate caveats surfaced honestly: it's an estimate; a dusty environment genuinely consumes filter life faster.

### 4.4 Advanced (enrichment, app-only, no hardware change)

**PM decay-curve effectiveness estimation:** when the fan runs in a closed room, intake PM decays roughly exponentially; fitting the decay constant over time gives an indirect CADR/effectiveness signal — a weakening decay rate across weeks hints at a clogging filter. Fragile (room size, door openings, outdoor infiltration) — ship as an "insights" feature with clear caveats, never as the health % source of truth.

### 4.5 VOC caveat for analytics

BME680 gas resistance is a raw proxy (no burn-in baseline, no BSEC calibration). It is already used in `overallStage` (bump when < 30 kΩ) — fine for the screen, but the app should treat `voc` as qualitative until/unless Bosch BSEC2 is adopted (licensing restrictions — future consideration).

---

## 5. Data Sync & History

**On connect (handshake):**
1. App reads Device Info (firmware version → protocol compatibility check) + Battery Service.
2. App reads all custom characteristics (full snapshot).
3. App reads Filter Counters (raw integrals → recompute health).
4. App sends `time` command (epoch). Device has no RTC; epoch is re-synced on **every** connect and drifts/resets across power cycles — device-side timestamps must never be trusted across reboots.

**While connected:** 1 Hz notify stream → app appends to its own local time-series (SQLite/Drift on Flutter) → powers dashboards, trends, decay analytics.

**Disconnected periods:** no data is collected (accepted for MVP). Flagged decision point: sparse on-device ring buffer in NVS/flash (e.g. 1 sample/10 min ≈ 144/day ≈ ~86 KB for 30 days) vs. accepting gaps. **Priority note:** `App-Required-Features.md` explicitly demands day/week/month history, which is only achievable if the device logs while the app is disconnected — so elevate this decision to **P3** (was P4). Interim P2 behavior: app-recorded history only while connected.

---

## 6. Mobile App Plan

### 6.1 Stack options

| Stack | BLE library | Pros | Cons |
|---|---|---|---|
| **Flutter** ✅ | `flutter_blue_plus` | One codebase, mature BLE plugin, great charts (`fl_chart`), local DB (`Drift`), fast iteration for a prototype | Larger binary; Dart BLE edge cases need careful state handling |
| React Native | `react-native-ble-plx` | One codebase, good BLE plugin | Streaming performance/JS bridge overhead; charts weaker |
| Native (Kotlin + Swift) | CoreBluetooth / Android BLE | Maximum BLE control | Two codebases, slowest for a prototype |

Recommendation: **Flutter** — assuming no existing team constraint, it minimizes time-to-dashboard.

App layering (keep protocol knowledge in one place):

```
BLE layer (scan/connect/notify)  →  Protocol codec (JSON v1 ↔ typed models)
→  Repository (counters math, history DB)  →  State mgmt (Riverpod/Bloc)  →  UI
```

The repository must be testable **without hardware** (mock the BLE/codec interfaces).

### 6.2 Permission & platform hurdles

| Platform | Hurdles |
|---|---|
| Android 12+ (API 31+) | `BLUETOOTH_SCAN` (with `neverForLocation`), `BLUETOOTH_CONNECT` — runtime permissions |
| Android ≤ 11 | **Location permission required for BLE scanning** — handle legacy path or set minSdk 31 |
| iOS | `NSBluetoothAlwaysUsageDescription` string; strict background limits — persistent connection only with background modes/state restoration; design for foreground-first |
| Both | Pairing/bonding dialogs (§7.8); auto-reconnect logic (backoff, bond persistence); "connection lost" UX |

### 6.3 MVP screens

1. Dashboard: live air status (stage, PM values), mirrors the device LCD at 1 Hz.
2. Environment/system: temp, humidity, VOC, fan, battery.
3. Filter page: life %, projected date, reset flow, counters detail.
4. Connection manager: device list, state, reconnect behavior.

---

## 7. Hurdles & Risks Master List

| # | Hurdle | Mitigation / decision |
|---|---|---|
| 7.1 | No persistence layer | Add NVS/`Preferences` counters in P0 (§4.2) |
| 7.2 | `millis()` rollover (~49.7 d) | Unsigned-delta accumulation everywhere a duration is computed |
| 7.3 | Flash wear from NVS writes | 5-min throttled writes; math in §4.2 shows <1%/yr endurance use |
| 7.4 | **Module variant check (blocking)**: PMS7003 sits on GPIO16/17, which are PSRAM pins on WROVER modules | Verify the board is a WROOM (or reassign UART to e.g. 25/26) **before** P1 |
| 7.5 | BLE stack resource budget alongside FastLED(I2S) + TFT + sensors | NimBLE (≈50% lighter than Bluedroid); confirm flash size ≥ 4 MB |
| 7.6 | Blocking 5 s boot screen | Bring BLE up **before** `showBootScreen()` so the app can connect during boot (cheap, do it in P1) |
| 7.7 | Update cadence mismatch (66 Hz loop vs BLE) | 1 Hz notify scheduler in `loop()`; on-change events for stage/charging/full (§3.3) |
| 7.8 | Security of write commands (`resetFilter`, `time` sync) — no auth today | Bonding + MITM protection on write characteristics; **passkey displayed on the TFT** (the purifier shows a 6-digit code; user types it in the app) is a natural fit for this hardware. MVP risk flag: shipping v1 unauthenticated is acceptable only if write exposure is consciously accepted |
| 7.9 | Single-connection limit | Accept one central; reject/queue additional centrals cleanly |
| 7.10 | VOC data quality (uncalibrated BME680 gas) | Treat as qualitative; BSEC2 = future option with license caveats (§4.5) |
| 7.11 | No OTA path today | Field firmware updates = USB reflash until P4 (WiFi OTA preferred over BLE OTA for size) |
| 7.12 | Protocol evolution | `v` field in every payload; codec isolated in the app for dual-version support |
| 7.13 | Time authority | Device epoch is app-supplied and reboot-volatile; never trust device timestamps across reboots (§5) |
| 7.14 | BLE testing | Use **nRF Connect** (read/notify/write simulation) as the pre-app harness; mock BLE layer for app tests |
| 7.15 | Connection robustness | Supervision timeout tuning, reconnect backoff, handle Android's flaky GATT refresh paths |
| 7.16 | Filter-model assumptions | Rated budget lives app-side (§4.2) so the device never hardcodes filter models |
| 7.17 | Fan PWM rework (4-pin fan) | ✅ Resolved in v3 (25 kHz + documented transistor polarity). No further fan/polarity firmware work is permitted under the §1.4 scope constraint |

---

## 8. Phased Roadmap

| Phase | Deliverable | Notes |
|---|---|---|
| **P0 — Persistence enablement (additive only)** | Add NVS raw counters + throttled writes with rollover-safe accumulation; firmware version string; wire the BLE-ready observation points (telemetry mirrors of existing globals). **No restructuring, no renames, no control-code changes** — §1.4 governs. | Foundation; cheap to test by watching serial output |
| **P1 — BLE telemetry** | NimBLE GATT server, Device Info + Battery services, custom characteristics with read+notify @ 1 Hz, boot-time BLE init. Verified with nRF Connect. | No commands yet — read-only |
| **P2 — App MVP** | Flutter skeleton, scan/connect, dashboard + system + filter pages, local history (while connected), health % from counters | Value: full remote visibility |
| **P3 — Security + offline history** | `resetFilter` (persistence mgmt) + time sync commands; bonding + passkey-on-TFT on writes; **on-device sparse history ring buffer** (required for week/month history, §5). Fan override is excluded per §1.4 | Value: correct reminders + true offline history |
| **P4 — WiFi / OTA / cloud (future)** | WiFi OTA, optional MQTT/HTTP sync, decay-curve insights shipped in app | Only if product direction wants remote/cloud features |
| **P5 — Hardware upgrade path (future)** | Differential pressure sensor across filter (best) or outlet PM sensor for direct filter health | Converts §4 estimate into measurement |

---

## 9. Hardware Revision — 4-Pin PWM Fan

The original fan was replaced with a standard 4-pin PWM fan — **ARCTIC P8 Max** (per v3 firmware comment) — (GND, V+, PWM control, TACH sense). Updated ESP32 code is in `docasa-air-purifier-v3.ino`. This change resolves a former open question (§4.1: "does the fan have a tach?") — it does — and introduces new firmware work.

**v3 status vs. plan:** PWM frequency and drive polarity are **already handled in v3** (§9.1–§9.2). The tach input is **not yet implemented** in v3 (§9.3 remains open).

### 9.1 PWM drive requirements change ✅ done in v3

v3 sets `FAN_PWM_FREQ 25000` (was 25 Hz in pt2) — correct for a 4-pin fan.

- 4-pin fans expect a **21–28 kHz PWM** signal (Intel spec, nominal **25 kHz**) on their dedicated PWM input.
- 8-bit resolution is fine at that frequency (10-bit also viable: 25 kHz × 2¹⁰ ≈ 25.6 MHz < 80 MHz LEDC clock).
- The fan's own internal driver handles commutation — the ESP32 only drives the logic-level PWM input now.
- v3 drives it through a **transistor stage** (see §9.2), so ESP32 duty and fan duty are inverses by design.

### 9.2 Duty polarity — chosen in v3, verify on the bench

v3 design: ESP32 → transistor → fan PWM line. Mapping per v3 comments: duty 255 = transistor fully active, grounds the fan PWM line = **fan OFF**; RPM targets map to `255 − rawPwm` (e.g. 4000 RPM target → duty 51). Bench-verify at least once: drive a few duty steps and confirm the fan's observed behavior matches "255=OFF … low duty=fast", since ARCTIC fans follow the Intel convention but the transistor wiring decides the final polarity. `updateFan()` in v3 targets RPM directly (stage → 0/1000/2000/3000/4000 RPM, scaled against a 5000 RPM ceiling).

### 9.3 Tach input (new telemetry) 🚫 deferred — outside firmware change scope

**Scope note (§1.4):** implementing the tach read requires new firmware/hardware code beyond BLE + persistence, so this item is **deferred** and sits on the "restricted future list" (§1.4), not the active roadmap.

**v3 caveat:** `currentFanRpm` is a **commanded target**, not a measured value — there is no tach wiring or feedback code yet, and the "FAN SPEED (RPM)" LCD row shows the target. BLE `fan` is therefore the target RPM.

- Tach = open-collector output, typically **2 pulses/rev**; wire to a spare **input-only** GPIO (34–39 ideal) with a pull-up to **3.3 V** (never 12 V).
- Count via the ESP32 PCNT peripheral (preferred, no ISR jitter) or a pin-change interrupt; RPM = pulses × 60 ÷ 2.
- What it buys (if ever unlocked): real fan speed %/RPM for system status, **stall detection** (RPM sag at constant duty), and an airflow signal for the filter model (§4) and decay analytics (§4.4).
- BLE effect: `rpm` added to the System Status payload (§3.4 example already updated). JSON v1 parsers must ignore unknown fields so this stays backward-safe.

### 9.4 Voltage rail check

Standard 4-pin fans are **12 V** (5 V variants exist). The pack is 4S Li-ion, 13.0–16.41 V raw — confirm what rail/regulator now feeds the fan before assuming 12 V direct from the pack.

---

## 10. Requirement Traceability (`App-Required-Features.md` ↔ hardware)

| # | Required feature | Data needed | Device source (existing sensor/variable) | Feasible with current hardware? | Work items |
|---|---|---|---|---|---|
| 1 | **Realtime readings & system status** (PM1, PM2.5, PM10, 5-level status, temp, humidity, VOC, fan speed, battery %) | All nine LCD data points | PMS7003 (`pm10Value`/`pm25Value`/`pm100Value` — v3 names, no rename), `overallStage`, BME680 (`temperature`, `humidity`, `gasResistance`), `currentFanRpm` in v3 (commanded target; measured RPM pending tach, §9.3), `batteryPct` (+`isCharging`, `isTrulyFull`, `smoothedVoltage` bonus) | ✅ **100% — no additional sensor hardware needed** | P0 counters/version string → P1 BLE characteristics → P2 dashboard |
| 2 | **History: day/week/month** (graphs/charts) | Timestamped time-series of the same stream | Same sensors; native cadence ≈ 1 Hz | ✅ data-wise; ⚠️ infrastructure-dependent | P2: app-side recording while connected; P3: on-device sparse NVS ring buffer so **disconnected periods are captured** (required for week/month views, §5); time authority = app epoch sync per connect (§5) |
| 3 | **Filter health monitoring + replacement notification** | Usage/load counters over time | NVS raw counters `fanSeconds`, `pmWeightedFanSeconds`, `runtimeHours` (§4, added in P0); `fanRpm` enriches with airflow signal | ✅ **estimation model** (like commercial purifiers); direct measurement stays a P5 upgrade (pressure/outlet sensor) | P0 counters → P2 app analytics + health % → P2/P3 local replacement notifications + `resetFilter` command (P3) |

**Verdict: all three required features are achievable with the present sensor set (PMS7003 + BME680 + battery/charge pins) and the new 4-pin fan.** No extra sensors are required for any listed feature. Remaining gaps are firmware *infrastructure* (NVS persistence, BLE, on-device history logging, time sync) and app-side work — covered by the roadmap in §8.

Honest caveats to carry into the app UX (§4.3–§4.5): VOC is a qualitative proxy; battery % is a voltage-model estimate without a fuel gauge; filter health is a load-weighted estimate, not a direct measurement.

---

## 11. Open Questions

1. Which exact ESP32 module/board (WROOM vs WROVER)? — decides the GPIO16/17 question (§7.4).
2. Fan electricals: 12 V or 5 V motor, and what rail/regulator feeds it? (§9.4)
3. Tach wiring (deferred — outside firmware change scope, §1.4): if ever unlocked, prefer spare input-only GPIO (34–39) + 3.3 V pull-up (§9.3).
4. Rated filter budget (hours + load budget) and which filter models the app must ship with.
5. Confirm target ESP32 Arduino core version + NimBLE-Arduino compatibility in the actual toolchain (§3.1).
6. Is unauthenticated MVP (P2) acceptable, or is bonding required from the first public build? (§7.8)

---

## 12. Handoff Package Summary (for a fresh context)

### 12.1 Repo state

| File | Role |
|---|---|
| `docasa-air-purifier-v3.ino` | **Active firmware baseline** (whitespace-fixed only; logic identical to the received original — verified by whitespace-ignoring diff). No BLE/NVS yet. |
| `Air_Purifier_Final_Revision_pt2.ino` | Previous firmware revision, kept for reference. Do not build from this. |
| `docs/IoT-Integration-Plan.md` | This document — authoritative plan, scope constraint (§1.4), GATT/payload contract, roadmap. |
| `docs/App-Required-Features.md` | Product requirements list (3 features), cross-referenced in §10. |
| `docs/Prompt-Planning.md` | Historical planning prompts. |

**Not yet in repo (prerequisites to provision):** build system (Arduino CLI/IDE config or PlatformIO), library set for firmware builds, and the entire Flutter app project.

### 12.2 Firmware build baseline

- Board: classic ESP32 dev module (exact variant UNCONFIRMED — see Open Question #1; WROVER would conflict with PMS7003 on GPIO16/17).
- Arduino IDE/CLI with **ESP32 Arduino core 3.x** (v3 code uses `ledcAttach(pin, freq, res)` — 3.x API only).
- Libraries used by v3: `FastLED` (with `FASTLED_ESP32_I2S true`), `Adafruit GFX`, `Adafruit ST7789`, `Adafruit Unified Sensor`, `Adafruit BME680`, `Adafruit PM25 AQI`. To be added for this work: **NimBLE-Arduino 2.x**.
- ⚠️ Arduino build rule: an `.ino` must live in a folder of the same name (`docasa-air-purifier-v3/docasa-air-purifier-v3.ino`). Currently at repo root — moving the file into its own folder (code untouched) is a permitted housekeeping step.

### 12.3 v3 revision delta (what changed vs. pt2 — for reading the code correctly)

| Change | pt2 → v3 |
|---|---|
| Fan PWM | 25 Hz → **25 kHz** (Intel 4-pin spec); transistor-driver polarity documented (255 = fan OFF) |
| Fan control model | `currentFanSpeed` (%) → `currentFanRpm` (commanded RPM targets 0/1000/2000/3000/4000 by stage) |
| LCD | System page fan row now shows raw RPM ("FAN SPEED (RPM)") |
| Battery smoothing | EMA factors 0.95/0.05 → 0.92/0.08 (voltage) and 0.98/0.02 → 0.92/0.08 (percentage); adds min-1%-delta display guard |
| Boot/LED animation | Boot LED interval 35→60 ms; LED chase speed map changed; comment headers trimmed |
| Not changed | Sensor read logic, AQI computation, battery/VOC thresholds, UART/I²C/SPI pins, boot duration, everything §1.4 freezes |
| Still absent in v3 | BLE, NVS/persistence, wall-clock, firmware version string, tach input (deferred, §9.3) |

### 12.4 What the new context will build (ordering per §8)

1. **ESP32 side (within §1.4 only):** NVS raw counters (`Preferences`, namespace `docasa`, 5-min throttled, unsigned-delta `millis()` math, uint64 for `pmWeightedFanSeconds`) + firmware version string + BLE stack (NimBLE GATT server, advertise name/UUID, read+notify characteristics at 1 Hz, JSON v1 payloads per §3.4, Device Info + Battery services) + later `resetFilter`/`time` commands with bonding (passkey on the TFT).
2. **Verification harness:** flash → confirm via serial monitor → exercise BLE with **nRF Connect** (reads, 1 Hz notifications, MTU negotiation) before any app code touches the device.
3. **App side (Flutter):** `flutter_blue_plus` + codec per §3.4 key dictionary + repository/health math per §4.2 + screens per §6.3 + permissions per §6.2.
4. **Behavior-preservation gate (every firmware change):** LCD pages, colors, animations, fan behavior, LED behavior, sensor cadence, boot sequence must be byte-for-byte unchanged in behavior; only new BLE/NVS/transmission code is present. If a change beyond §1.4's list is ever proposed, it requires explicit user approval first.
