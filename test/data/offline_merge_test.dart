import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:docasa_app/data/db/database.dart';
import 'package:docasa_app/data/history_compactor.dart';
import 'package:docasa_app/data/history_repository.dart';
import 'package:docasa_app/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Offline-window ingestion + the history merge (Contract v1.1 §10.3, D-028).
void main() {
  late AppDatabase db;
  setUp(() {
    db = AppDatabase.test(NativeDatabase.memory());
  });
  tearDown(() => db.close);

  final windowBase = DateTime(2026, 11, 5, 12).millisecondsSinceEpoch;

  Future<void> seedAppMinute(int minuteStartMs, {int stage = 1}) async {
    await db.into(db.minuteAggregates).insert(MinuteAggregatesCompanion.insert(
          minuteStartMs: Value(minuteStartMs),
          pm1: 1,
          pm25: 44,
          pm10: 55,
          temp: 24,
          humidity: 40,
          voc: 30,
          fanRpm: 0,
          batteryPct: 80,
          batteryV: 15,
          stageMax: stage,
          stage1Count: 60,
          stage2Count: 0,
          stage3Count: 0,
          stage4Count: 0,
          stage5Count: 0,
          sampleCount: 60,
        ));
  }

  Future<void> seedWindow({
    required int startMs,
    required int pmMean,
    List<int> stageSec = const [300, 300, 0, 0, 0],
  }) async {
    final slot = (startMs ~/ 600000) % 16384;
    await db.into(db.deviceWindows).insert(DeviceWindowsCompanion.insert(
          bootId: 3,
          slot: slot,
          windowStartMs: startMs,
          pmMin: pmMean - 2,
          pmMean: pmMean,
          pmMax: pmMean + 2,
          stage1Sec: stageSec[0],
          stage2Sec: stageSec[1],
          stage3Sec: stageSec[2],
          stage4Sec: stageSec[3],
          stage5Sec: stageSec[4],
        ));
  }

  test('app-recorded minutes win; offline windows back-fill GAPS', () async {
    final m0 = windowBase; // bucket where the app recorded
    final m1 = windowBase + 60000; // 1-min later — offline only
    await seedAppMinute(m0);
    await seedWindow(startMs: m0, pmMean: 30);
    // window tops out 9 min later, covering m0..m9 buckets.
    await seedWindow(startMs: m1 + 600000, pmMean: 88);
    final s = await const HistoryRepository()
        .load(db, HistoryRange.day, HistoryMetric.pm25, nowMs: m1 + 3600000);
    final b0 = (m0 ~/ 60000) * 60000;
    final v0 = s.points.elementAt((b0 - s.windowStartMs) ~/ 60000);
    final v1 = s.points
        .elementAt(((m1 ~/ 60000) * 60000 - s.windowStartMs) ~/ 60000);
    expect(v0, closeTo(44, 0.001), reason: 'app row wins in-place');
    expect(v1, closeTo(30, 0.001), reason: 'offline window fills the gap');
    // donut stage split from merged windows (2 windows × [300+300] s):
    expect(s.stageCounts[0], greaterThan(0));
    expect(s.stageCounts[1], greaterThan(0));
    expect(s.stageCounts[0] + s.stageCounts[1], 1200,
        reason: 'exact split sums (2 windows × 600 s)');
  });

  test('device windows age out at the hour-tier retention', () async {
    await seedWindow(startMs: windowBase, pmMean: 50);
    await HistoryCompactor().run(db, nowMs: windowBase + 91 * 24 * 3600000);
    final left = await db.select(db.deviceWindows).get();
    expect(left, isEmpty);
  });

  test('sync water-mark round-trip picks the most recent boot', () async {
    final repo = SettingsRepository(db);
    await repo.saveSyncWatermark(2, 300, windowBase);
    await repo.saveSyncWatermark(7, 900, windowBase + 1000);
    final any = await repo.lastSyncWatermarkAny();
    expect(any, isNotNull);
    expect(any!.$2, 7);
    final w7 = await repo.loadSyncWatermark(7);
    expect(w7, isNotNull);
    expect(w7!.$1, 900);
    expect(w7.$2, windowBase + 1000);
  });
}
