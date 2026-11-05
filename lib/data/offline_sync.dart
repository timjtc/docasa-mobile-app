import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../ble/fbp/fbp_docasa_connection.dart';
import '../ble/fbp/fbp_offline_sync.dart';
import '../protocol/contract.dart';
import 'db/database.dart';
import 'settings_repository.dart';

/// Offline-history orchestration (Contract v1.1 §10.3, D-028).
///
/// Runs ONCE per connection, right after the connect handshake:
/// 1. Load this boot's water-mark from the settings KV (`sync.<bootId>` —
///    but the boot id is only known after the FIRST status read, so the
///    first arm always uses the last-known water-mark, and a second arm
///    re-corrects when the reported boot id differs).
/// 2. Drain the ring via the transport.
/// 3. Map slots to phone wall-clock: anchorMs = now − endSlot × 10 min
///    (refreshed every connect — the phone is the time authority, §6.7/§7.13),
///    ingest into `device_windows`, persist the new water-mark/anchor.
///
/// Errors are absorbed and logged: a failed sync degrades to the
/// app-recorded-with-gaps view (pre-v1.1 behavior), never to a crash.
class OfflineSyncService {
  OfflineSyncService(this._db, this._settings);

  final AppDatabase _db;
  final SettingsRepository _settings;

  bool _busy = false;

  Future<void> syncNow(FbpDocasaConnection conn) async {
    if (_busy) return;
    _busy = true;
    try {
      final dev = conn.pickedDevice;
      if (dev == null) return;

      // First arm: use ANY stored water-mark from the most recent sync (the
      // boot id on the device may differ after a reboot; the second arm
      // below re-corrects once the status read reports the boot id).
      final lastKnown = await _settings.lastSyncWatermarkAny();
      final drain = OfflineHistoryDrain(dev);
      // First arm: from oldest — the device's current boot id is unknown
      // before the status read (§10.3); the ingested rows idempotently
      // (INSERT OR REPLACE) cover the common contiguity case.
      var result = await drain.drain(0);

      // Re-arm from the stored slot when the reported boot id matches the
      // one stored (fully-synced connect → status read only).
      if (result != null &&
          lastKnown != null &&
          result.bootId == lastKnown.$2) {
        final stored = await _settings.loadSyncWatermark(result.bootId);
        final servedLow = result.records.first.$1;
        if (stored != null &&
            stored.$1 > servedLow &&
            stored.$1 <= result.nextSlotAfterLast) {
          result = await drain.drain(stored.$1);
        }
      }
      if (result == null) return; // fully synced, or no v1.1 firmware

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      // Anchor: the slot AFTER the last closed window corresponds to "now"
      // on boot-uptime scale (§10.3). Re-anchored every connect.
      final res = result; // promoted snapshot for the batch closure
      final anchorMs =
          nowMs - res.nextSlotAfterLast * DocasaContract.offlineWindowMs;
      await _db.batch((b) {
        for (final (slot, w) in res.records) {
          b.insert(
            _db.deviceWindows,
            DeviceWindowsCompanion.insert(
              bootId: res.bootId,
              slot: slot,
              windowStartMs: anchorMs + slot * DocasaContract.offlineWindowMs,
              pmMin: w.pmMin,
              pmMean: w.pmMean,
              pmMax: w.pmMax,
              stage1Sec: w.stageSeconds[0],
              stage2Sec: w.stageSeconds[1],
              stage3Sec: w.stageSeconds[2],
              stage4Sec: w.stageSeconds[3],
              stage5Sec: w.stageSeconds[4],
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
      await _settings.saveSyncWatermark(
          result.bootId, result.nextSlotAfterLast, anchorMs);
      debugPrint('FBP: offline sync — boot=${result.bootId} '
          '+${result.records.length} windows (watermark ${result.nextSlotAfterLast})');
    } catch (e) {
      // Absorb: history stays app-recorded-with-gaps for this connect.
      debugPrint('FBP: offline sync failed (graceful): $e');
    } finally {
      _busy = false;
    }
  }
}
