# DOCASA Bench Runbook — flashing & G1/G2 verification

Date prepared: 2026-10-30 · Applies to firmware **v4.1.0** (`firmware/docasa-air-purifier-v4/`)
Use this when the ESP32 is physically available. It covers the flashing setup that the original
author did in Arduino IDE, plus the Phase 1/2 gate checks (G1, G2).

---

## 0. Already provisioned (nothing to do)

- **No Arduino IDE needed.** `arduino-cli` 1.5.1 replicates it and is already set up:
  ESP32 core 3.3.12, all v3 libraries, NimBLE-Arduino 2.5.2, ArduinoJson 7.4.3 (see D-013/D-014).
  (If you ever want the IDE GUI anyway, it shares `~/.arduino15` — everything above appears in it.)
- v4.1 compiles clean: 732,643 B flash (55 %), 40,572 B RAM (12 %), 0 warnings.
- Diff gate passes: `tools/firmware-diff-check.sh` → 0 removed/changed lines vs v3 baseline.

## 1. USER ACTION — one-time machine setup

1. **Serial port permission** (your account is not in `dialout`):
   ```
   sudo usermod -aG dialout $USER
   ```
   then log out & back in (or `newgrp dialout` in the current shell).
2. **Install nRF Connect** (free, Nordic Semiconductor) from the Play Store on your phone —
   needed for the G2 BLE verification.
3. Plug the ESP32 into the machine with a **data-capable USB cable** (charge-only cables are the
   #1 cause of "no port appears").

## 2. Flash (assistant or user can run once the device is plugged in)

```bash
# 1. Find the port (expect /dev/ttyUSB0 for CP2102 boards, /dev/ttyACM0 for others)
ls /dev/ttyUSB* /dev/ttyACM*

# 2. Confirm the board is seen
arduino-cli board list

# 3. Upload
arduino-cli upload -p /dev/ttyUSB0 --fqbn esp32:esp32:esp32 firmware/docasa-air-purifier-v4

# 4. Watch the serial log (Ctrl-C to exit)
arduino-cli monitor -p /dev/ttyUSB0 -c baudrate=115200
```

**If upload fails:** hold the **BOOT** button on the ESP32 while the "Connecting..." phase runs,
then release. **If the port never appears:** try another cable/port; classic dev boards use a
CP2102/CH340 USB-serial chip that Linux supports out of the box.

**Expected boot serial output (v4.1):**
```
[DOCASA IO] firmware 4.1.0 (protocol v1)
[DOCASA IO] NVS restored: fs=0 pwfs=0 on=0h
[DOCASA IO] BLE advertising as 'DOCASA-AirPurifier'
```
followed by `[DOCASA IO] fs=… pwfs=… onSec=…` every 60 s.

## 3. Gate G1 — persistence & behavior (Development-Process §4)

| # | Check | Pass condition |
|---|---|---|
| 1 | Counters grow | `fs`/`pwfs` increase while fan runs (stage ≥ 2); `fs` static at stage 1 (fan off) |
| 2 | Power-cycle survival | Power off ≥ 10 s, reboot: "NVS restored" shows the pre-shutdown values (≤ 5 min loss acceptable, Plan §4.2) |
| 3 | Load weighting | Dirtier air (stage up) → `pwfs` grows visibly faster than `fs` |
| 4 | Behavior preservation | LCD pages/colors/animations, LED chase, fan response, boot animation — all identical to v3 |
| 5 | **FastLED visual check** (G0 note) | LED strip chase renders normally — FastLED 3.10.8 reworked ESP32 drivers; if glitchy, pin FastLED ≤ 3.9.x and re-verify (D-013) |

→ Write `docs/gate-reports/G1.md`, tag `gate/G1`.

## 4. Gate G2 — BLE telemetry via nRF Connect (Development-Process §5)

1. **Scan**: device appears as `DOCASA-AirPurifier`, filterable by the service UUID
   `d0ca5a0e-975a-4408-9059-a93d3207072f` (scan response).
2. **Connect during boot**: connect while the boot animation still plays (advertising starts
   before `showBootScreen()`).
3. **Device Info (0x180A)**: Manufacturer `DOCASA`, Model `DOCASA Air Purifier`,
   Firmware Revision `4.1.0`, Hardware Revision `ESP32-WROOM-v3`.
4. **Battery (0x180F/0x2A19)**: read matches LCD %; enable notify → 1 Hz updates.
5. **Telemetry service**: subscribe Air Quality / Environment / System Status → **1 Hz JSON**
   matching the LCD values live; payloads match `BLE-Protocol-Contract.md` §4 exactly.
6. **On-change**: trigger a stage change (breathe near the PM sensor / dusty air) → Air Quality
   notify arrives immediately, not on the next tick. Same for charge plug/unplug → System Status.
7. **Filter Counters (read-only)**: read returns `{"v":1,"fs":…,"pwfs":…,"on":…}`; no notify.
8. **Command char**: write `{"cmd":"resetFilter"}` → serial logs `cmd ignored`, counters
   unchanged; write `not json` → ignored, connection stays up (Contract §5).
9. **MTU**: request MTU 247 → accepted; payloads ≤ ~77 B arrive intact either way.
10. **Disconnect/reconnect**: walk away or toggle Bluetooth → device re-advertises (serial log);
    reconnect 10×; leave connected overnight (no crash, no heap growth, counters still sane).
11. **Single central**: second phone's connect attempt while connected → cannot connect
    (advertising paused).

→ Write `docs/gate-reports/G2.md`, tag `gate/G2`. G1+G2 pass = Plan P0+P1 complete.

## 5. What is deliberately NOT in v4.1 (do not "fix" on the bench)

- `resetFilter` command → Phase 5 (with security ruling D-010).
- Fan override / any `updateFan()` change → Plan §1.4 restricted list (never without approval).
- Bonding/passkey → Phase 5 (writes are unauthenticated in v4.1 — accepted MVP risk, Plan §7.8).
- Measured RPM (tach) → deferred (Plan §9.3).
