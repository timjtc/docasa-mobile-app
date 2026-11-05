# Session log — 2026-11-05: BLE "Connecting" hang triage (Windows host, post-handoff)

Task: app selects `DOCASA-AirPurifier` in the picker → CONNECTING indicator spins forever.
Authority: docs/Development-Process.md §11 next-step (1), D-019/D-020 playbook: 3-layer probe —
device Serial, nRF Connect G2 checklist, app `logcat -s flutter` FBP trail. This session ran the
**logcat layer** live. **RESOLVED — root cause found app-side, fixed, verified end-to-end on the
device (D-025).** Serial/nRF layers (G1/G2 formalities) remain owed to the bench.

## Procedure (methodically executed)
1. Repo re-analysis on new host: graphify queries for BLE connect flow + dashboard/picker;
   read Development-Process.md, App-ADB-Test.md, Decision-Log (D-015…D-024), Bench-Runbook.md,
   BLE-Protocol-Contract.md §1–§6; FBP transport + picker + providers + gate UI sources; firmware
   GATT source (v4.1.1 — DIS strings + READ|NOTIFY properties per Contract).
2. Force consistency (as ordered): `flutter analyze` baseline → rebuilt the BLE-test artifact
   (`tools/build-ble-test-apk.sh`) → `adb install -r releases/docasa-ble-test-20261105.apk`
   onto the Samsung A34 (RFCW303YC7M; re-authorized after `adb kill-server` restart).
3. Live capture: `adb logcat -c` → full capture to tmp file → cold start → picker → picked the
   purifier → recorded the FBP decision trail (raw log retained in msys tmp, not committed).
4. Findings + fix + re-verification below; gates: analyze 0 issues, 54/54 tests, Decision-Log
   D-025, session artifacts in the APK name (same-dated artifact rebuilt post-fix).

## Findings

- **Failing stage pinpointed by the trail (pre-fix build):** BLE radio/stack fully healthy —
  `connect` (cached "already connected"), `requestMtu` 247 → GATT_SUCCESS, `discoverServices`
  → **5 services, GATT_SUCCESS** (twice per cycle: `_handshake` then `readDeviceInfo` both
  rediscover) — then `FBP: link failed: Bad state: No element` at
  `FbpDocasaConnection.readDeviceInfo.read` (line 211). FBP backoff loop then restarted forever
  → permanent CONNECTING + spinner (every failure stage maps to the same UI, as suspected in
  App-ADB-Test.md session 3).
- **Root cause (app-side):** `readDeviceInfo` compared runtime characteristic UUIDs against the
  Contract's **short-form** constants with plain string equality:
  `c.uuid.str128 == uuid` where `uuid` = `'2A29'`… but `str128` on Android always returns the
  full 128-bit normalized form (`'00002a29-0000-1000-8000-00805f9b34fb'`). Never equal → the
  FIRST DIS read threw → handshake died on every connect. The custom telemetry UUIDs in
  `contract.dart` are stored full-form, which is why scanning (`service §D-002` row) worked and
  only DIS reads died. Never hit before because D-019/D-020 practice rounds had zero DOCASA
  advertisements (no hardware powered).
- **Firmware exonerated:** 5 services incl. `180A` with 2A29/2A24/2A26/2A27 READ values
  (`DOCASA` / `DOCASA Air Purifier` / `4.1.1`) matching Contract §3 and the D-020(b)
  verification predicate; confirmed over the air post-fix (handshake device info line).
- **Evidence trail (fixed build, pid 2882):**
  ```
  FBP: state → connecting
  FBP: handshake device info: mfg=DOCASA model=DOCASA Air Purifier fw=4.1.1
  FBP: handshake done (CCCDs subscribed), link live
  FBP: state → connected            (pick → connected ≈ 1.4 s)
  FBP: first complete frame decoded
  ```
  Screen: CONNECTED badge + live PM2.5 36 / PM1.0 24 / PM10 43 µg/m³, stage POOR, "live ·
  updated 14:28".

## Fix (D-025)

`lib/ble/fbp/fbp_docasa_connection.dart` `readDeviceInfo().read()`: compare via
`c.uuid == Guid(uuid)` (FBLP `Guid ==` normalizes short-form to full 128-bit, lowercase map).
One-line change; missing-characteristic behavior unchanged (`StateError` → backoff loop, as
designed for wrong-device rejection). Telemetry UUID comparisons use full-form constants on
both sides and are left untouched.

## Follow-ups
- G4 checklist remainder on the phone (walk-away disconnect → backoff reconnect; history
  survives restart; filter-health % plausible; time sync each connect — the last two are now
  observable indirectly via Device/Filter pages) → `gate-reports/G4.md`.
- G1/G2 formalities still owed to the bench (Serial + nRF Connect) — the over-the-air
  handshake read of fw 4.1.1 is strong evidence but not the formal gate.
- After G4: restore `withServices` scan filtering + consider kDebugMode-gating the trail
  (D-020d/D-019 notes unchanged).
