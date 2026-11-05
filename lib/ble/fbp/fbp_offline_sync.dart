import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../protocol/codec.dart';
import '../../protocol/contract.dart';
import '../../protocol/models.dart';

/// Result of one offline drain run: delivered records with their slots plus
/// the water-mark to persist (slot AFTER the last consumed record). Empty
/// [records] means the device is already fully synced.
class OfflineDrainResult {
  const OfflineDrainResult({
    required this.bootId,
    required this.nextSlotAfterLast,
    required this.records,
  });

  final int bootId;
  final int nextSlotAfterLast;
  final List<(int, OfflineWindowSample)> records;
}

/// Offline-history drain against a connected device (Contract v1.1 §10.3).
///
/// Transport only: arms the cursor at the caller's water-mark, reads the ring
/// status JSON, then pulls packed records until an empty body or the reported
/// bound. Water-mark/anchor persistence and ingestion live in
/// `data/offline_sync.dart` (the transport knows nothing of time mapping).
///
/// Termination: the status read reports `first`/`count`; the drain stops at
/// the bound, at an empty read, or at the first invalid record (torn write /
/// power loss → that window becomes a phone-side gap, ≤1 window, §10.3).
class OfflineHistoryDrain {
  OfflineHistoryDrain(this._device);

  final BluetoothDevice _device;

  Future<OfflineDrainResult?> drain(int lastConsumedSlot) async {
    final services = await _device.discoverServices();
    BluetoothCharacteristic? findChar(String uuid) {
      for (final s in services) {
        for (final c in s.characteristics) {
          if (c.uuid.str128.toLowerCase() == uuid.toLowerCase()) return c;
        }
      }
      return null;
    }

    final cmd = findChar(DocasaContract.commandUuid);
    final offline = findChar(DocasaContract.offlineUuid);
    if (cmd == null || offline == null) return null; // pre-v1.1 firmware

    // 1) Arm: `after` = the app's last consumed slot; absent-equivalent 0
    //    drains from the oldest record the ring still holds (§5/§10.3).
    await cmd.write(utf8.encode(
        jsonEncode(<String, dynamic>{'cmd': 'offlineLog', 'after': lastConsumedSlot})));

    // 2) Ring status (first post-arm read): {"v":1,"boot":..,"first":..,"count":..}
    final status = utf8.decode(await offline.read());
    final dynamic decoded;
    try {
      decoded = jsonDecode(status);
    } catch (_) {
      throw StateError('offline ring status not JSON: $status');
    }
    if (decoded is! Map<String, dynamic> || decoded['v'] != 1) {
      throw StateError('offline ring status unsupported: $status');
    }
    final bootId = (decoded['boot'] as num).toInt();
    final first = (decoded['first'] as num).toInt();
    final count = (decoded['count'] as num).toInt();
    final bound = first + count; // exclusive
    var slot = first;            // records are served starting AT `first`

    // 3) Drain: consecutive reads until the bound or an empty body. Each
    //    read returns ≤ MTU−1 bytes of whole 16 B records.
    final records = <(int, OfflineWindowSample)>[];
    while (slot < bound) {
      final chunk = await offline.read();
      if (chunk.isEmpty) break; // drained
      final recCount = chunk.length ~/ DocasaContract.offlineRecordBytes;
      if (recCount == 0) break; // non-multiple remainder → treat as drained
      for (var i = 0; i < recCount; i++) {
        if (slot >= bound) break;
        final sample = DocasaCodec.decodeOfflineRecord(chunk, i * DocasaContract.offlineRecordBytes);
        records.add((slot, sample));
        slot++;
      }
    }
    if (records.isEmpty) return null;
    return OfflineDrainResult(bootId: bootId, nextSlotAfterLast: slot, records: records);
  }
}
