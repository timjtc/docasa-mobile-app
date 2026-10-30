import 'package:drift/drift.dart';

import '../../ble/fake/fake_generator.dart';
import 'db/database.dart';
import 'history_compactor.dart';

/// Demo tool (Phase 3): generates `days` of plausible history straight into
/// `raw_samples` using the same device emulator, with realistic gaps (device
/// "off" overnight), then compacts. Lets day/week/month charts be demonstrated
/// instantly instead of waiting days of live recording.
class HistorySeeder {
  const HistorySeeder();

  static const int _chunk = 3600;

  Future<void> seed(
    AppDatabase db, {
    int days = 7,
    int seed = 7,
    int? nowMs,
  }) async {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final start =
        now - days * 24 * 3600 * 1000 - (now % 60000); // align to minute
    final gen = FakeDocasaGenerator(seed: seed);

    // Simulated wall-clock per step.
    var t = start;
    final end = now - (now % 60000);
    final buffer = <RawSamplesCompanion>[];

    while (t < end) {
      final localHour =
          DateTime.fromMillisecondsSinceEpoch(t).hour;
      final deviceOn = localHour >= 7 && localHour < 23; // "off" overnight
      if (deviceOn) {
        final tick = gen.step();
        final a = tick.air, e = tick.env, s = tick.sys;
        buffer.add(RawSamplesCompanion.insert(
          timeMs: Value(t),
          pm1: a.pm1,
          pm25: a.pm25,
          pm10: a.pm10,
          stage: a.stage,
          temp: e.temperature,
          humidity: e.humidity,
          voc: e.vocKOhms,
          fanRpm: s.fanRpm,
          batteryPct: s.batteryPct,
          charging: s.charging,
          batteryV: s.batteryVoltage,
        ));
      }
      t += 1000;
      if (buffer.length >= _chunk) {
        await _insert(db, buffer);
        buffer.clear();
      }
    }
    if (buffer.isNotEmpty) await _insert(db, buffer);
    await const HistoryCompactor().run(db, nowMs: now);
  }

  Future<void> _insert(AppDatabase db, List<RawSamplesCompanion> rows) async {
    try {
      await db.batch((b) => b.insertAll(db.rawSamples, rows));
    } on Exception {
      // ignore duplicate-key batches (demo data)
    }
  }
}
