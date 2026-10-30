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
arduino-cli compile --fqbn esp32:esp32:esp32dev firmware/docasa-air-purifier-v4
```
