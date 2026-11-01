# Firmware

All ESP32 / hardware code lives in this directory (project directive, 2026-10-30).

- `baseline/` — frozen reference revisions, **never built or edited**:
  - `docasa-air-purifier-v3.ino` — the running device baseline; diff target for the
    behavior-preservation gate (`docs/Development-Process.md` §10.2)
  - `Air_Purifier_Final_Revision_pt2.ino` — previous revision, kept for reference
- `docasa-air-purifier-v4/` — the working sketch (v3 + additive BLE/NVS only, per the
  Plan §1.4 scope constraint). Seeded byte-identical to v3 at Phase 0.

Build check (arduino-cli, ESP32 Arduino core 3.x):

```
arduino-cli compile --fqbn esp32:esp32:esp32 firmware/docasa-air-purifier-v4
```

Flashing + bench verification (G1/G2): see `docs/Bench-Runbook.md`.
Behavior-preservation gate (run before every firmware commit):

```
tools/firmware-diff-check.sh        # must report 0 removed/changed lines
```

## Flashing v4.1.1 on a fresh Windows Arduino IDE (hardware maintainer, 2026-11-01)

Environment baseline: the maintainer's IDE previously flashed v3 fine. v4.1.1 (same as verified v4.1.0 plus the resetFilter acceptance) is
v3-additive only, so the flow is identical — the deltas are **two new libraries** and one
version check.

1. **ESP32 board core**: Boards Manager → `esp32` by Espressif Systems → install/verify
   **3.3.12** (compile-verified; any ≥3.0 core likely compiles, but stick to 3.3.12 to match
   the verified build — core 3.x is required, the old 2.x era core is not sufficient).
2. **New libraries** (Library Manager):
   - **NimBLE-Arduino** by h2zero — **2.5.2** (BLE stack used by the IoT additions;
     D-014).
   - **ArduinoJson** by Benoit Blanchon — **7.4.3**. If Library Manager doesn't offer the
     exact version, install from the GitHub release zip.
3. **Existing libraries** (should already be there from v3; verify only if compile fails):
   FastLED 3.10.8 · Adafruit ST7735 and ST7789 Library 1.12.0 (+ GFX 1.13.0,
   BusIO 1.17.4, Unified Sensor prerequisite 1.1.15) · Adafruit BME680 2.0.6 ·
   Adafruit PM25 AQI Sensor 2.0.0.
4. **Sketch**: open `firmware/docasa-air-purifier-v4/docasa-air-purifier-v4.ino`
   (`FIRMWARE_VERSION 4.1.1`). Board: **ESP32 Dev Module** (same as used for v3), other
   settings (port, upload speed, partition scheme = default) unchanged — the sketch fits
   the default partition (verified ~55 % flash, 12 % RAM, 0 warnings).
5. Flash → expect v3 behavior unchanged (TFT/LED/dials/BME), then run the G1/G2 checklist
   in `docs/Bench-Runbook.md` (NVS persistence power-cycle test + nRF Connect GATT checks:
   1 Hz JSON on subscribe, `time` write, `resetFilter` ignored — accepted in v4.1.1).
   Record the results into `docs/gate-reports/G1.md` and `G2.md` — those gates close Phases
   1+2 (D-015).

### Windows troubleshooting (observed 2026-11-01, maintainer IDE)

Symptoms seen: `ld.exe: ...FastLED\fl\build\objs.a: member (fl.fx+.cpp.o.o) in archive is
not an object` + `collect2.exe: error: ld returned 1 exit status`.
Fixes in order (all confirmed relevant to that log):

1. **The FastLED under `OneDrive\Documents\Arduino\libraries` must be exactly 3.10.8.**
   Newer FastLED ships the `fl/` prebuilt-archive (`objs.a`) subsystem that the
   Windows linker rejects in these combos; downgrade/replace first, then continue.
2. **Purge the stale build cache** — delete
   `C:\Users\<user>\AppData\Local\arduino\sketches\9A649168BE3A3B733FA365988EEFB672`
   (or the whole `sketches` folder) and recompile. A corrupted cached `objs.a` keeps
   failing even after the library is fixed.
3. **Move the sketchbook out of OneDrive** — File → Preferences → Sketchbook location
   → a non-synced path (e.g. `C:\Arduino`). OneDrive-synced libraries reliably produce
   archive/byte-corruption of this kind.
4. Log noise that is NOT fatal: "Multiple libraries were found for Preferences.h" (the
   core-bundled one is used — informational) — no action needed.
5. Board core in that log was **3.3.10** — bump to **3.3.12** in Boards Manager to
   exactly match the verified build (any 3.3.x likely compiles, 3.3.12 removes doubt).
6. Compile against the repo sketch (`docasa-air-purifier-v4.ino`, 4.1.1) — ad-hoc AI-
   edited variants in `Downloads` have unknown drift and their errors are un-debuggable
   against the contract.
