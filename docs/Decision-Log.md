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

---

### Backlog (unscheduled, non-blocking)

- Rename Android `applicationId` from `com.example.docasa_app` before any distribution.
- Plan OQ #2 (fan voltage rail) — verify at next bench session; no app/firmware impact.
- `tools/firmware-diff-check.sh` convenience script (Phase 0 optional).
