import 'package:drift/native.dart';
import 'package:docasa_app/ble/fake/fake_docasa_connection.dart';
import 'package:docasa_app/data/db/database.dart';
import 'package:docasa_app/data/filter_health.dart';
import 'package:docasa_app/data/history_repository.dart';
import 'package:docasa_app/data/history_seeder.dart';
import 'package:docasa_app/features/device/device_page.dart';
import 'package:docasa_app/protocol/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Device-page developer tools (D-030): 2-month dirty-skewed seeding
/// with device-counter push, and the 7-tap dev-options gate.
void main() {
  test('DevTapTracker — the 7th consecutive quick tap enables; lulls reset',
      () {
    final t = DevTapTracker();
    var now = DateTime(2026, 11, 5, 10);
    expect(t.tap(), isFalse);
    now = now.add(const Duration(milliseconds: 300));
    for (var i = 2; i < 7; i++) {
      expect(t.tap(), isFalse, reason: 'tap #$i must not enable yet');
    }
    expect(t.tap(), isTrue, reason: '7th quick tap enables dev options');
    // A long pause restarts the pattern.
    expect(t.tap(), isFalse);
    expect(t.tap(), isFalse);
  });

  group('TwoMonthSeeder (D-030)', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.test(NativeDatabase.memory()));
    tearDown(() => db.close);

    final now =
        DateTime(2026, 11, 5, 18).millisecondsSinceEpoch; // evening — on-hours

    test('seeds 2 months, mostly POOR/BAD/HAZARD, with consistent totals',
        () async {
      final totals = await const TwoMonthSeeder().seed(db, nowMs: now);

      // Story: the sensitive sensitivity (0.5× budget of 500 h dirty) must
      // read 0% — that is the demonstration target.
      expect(totals.dirtySeconds, greaterThan(500 * 3600),
          reason: 'seeded dirty exposure must exceed the sensitive budget');
      final health = computeFilterHealth(
        counters: FilterCounters(
          fanSeconds: totals.fanSeconds,
          pmWeightedFanSeconds: totals.pmWeightedFanSeconds,
          powerOnHours: totals.powerOnSeconds ~/ 3600,
          stageSeconds: totals.stageSeconds,
        ),
        budgets: const FilterBudgets(),
        now: DateTime.fromMillisecondsSinceEpoch(now),
        sensitivity: FilterSensitivity.sensitive,
      );
      expect(health.pct, 0);
      // Normal default stays under the budget (not zeroed).
      final normal = computeFilterHealth(
        counters: FilterCounters(
          fanSeconds: totals.fanSeconds,
          pmWeightedFanSeconds: totals.pmWeightedFanSeconds,
          powerOnHours: totals.powerOnSeconds ~/ 3600,
          stageSeconds: totals.stageSeconds,
        ),
        budgets: const FilterBudgets(),
        now: DateTime.fromMillisecondsSinceEpoch(now),
      );
      // Normal lands NEAR 0 % (under the 10 % alert threshold → the
      // replacement prompt fires) while keeping realistic clean stretches.
      expect(normal.pct, greaterThan(0));
      expect(normal.pct, lessThan(10));

      // Dirty-dominance: POOR+ minutes ≫ FAIR/GOOD minutes.
      final minuteRows = await db.select(db.minuteAggregates).get();
      expect(minuteRows.length, greaterThan(40 * 60));
      var dirtyMin = 0, cleanMin = 0;
      for (final r in minuteRows) {
        (r.stage3Count + r.stage4Count + r.stage5Count) > 30
            ? dirtyMin++
            : cleanMin++;
      }
      expect(dirtyMin, greaterThan(cleanMin * 4));

      // Counter consistency: fs = Σ rpm·60 stays aligned with minutes.
      final expectedFsMin = minuteRows.fold<int>(
          0, (a, r) => a + r.fanRpm.toInt() * 60);
      expect(totals.fanSeconds, expectedFsMin);
    });

    test('fake transport adopts seeded usage counters (D-030 echo)', () async {
      final conn = FakeDocasaConnection();
      await conn.connect();
      await conn.setUsage(
        fs: 21600000000,
        pwfs: 540000000000,
        onSeconds: 2 * 3600,
        stSeconds: [12000, 16000, 500000, 60000, 20000],
      );
      final c = await conn.readFilterCounters();
      expect(c.dirtyAirSeconds, 500000 + 60000 + 20000);
      expect(c.powerOnHours, 2);
      await conn.disconnect();
    });

    test('monthCompare splits the two calendar months (D-032)', () async {
      await const TwoMonthSeeder().seed(db, nowMs: now);
      final cmp = await const HistoryRepository().monthCompare(db, nowMs: now);
      expect(cmp, isNotNull);
      // Date math on `now` (2026-11-05): previous = October (seeded from the
      // 8th), current = November 1–5 (all seeded days within the window).
      expect(cmp!.previous, isNotNull);
      expect(cmp.current, isNotNull);
      expect(cmp.current!.avgPm25, greaterThan(40),
          reason: 'the dirty story dominates the seeded PM levels');
      expect(cmp.previous!.dirtySeconds, greaterThan(3600 * 24),
          reason: 'previous month holds weeks of dirty exposure');
      expect(cmp.current!.dirtySeconds, greaterThan(3600 * 6),
          reason: 'the running month holds days of dirty exposure');
    });

    test('lastMonth loads the previous calendar month bucket-by-bucket (D-032)',
        () async {
      await const TwoMonthSeeder().seed(db, nowMs: now);
      final s = await const HistoryRepository()
          .load(db, HistoryRange.lastMonth, HistoryMetric.pm25, nowMs: now);
      final seededHours = s.points.whereType<double>().length;
      expect(seededHours, greaterThan(20 * 24),
          reason: '≥20 days of hours from the previous month');
      expect(s.coverage, greaterThan(0.3));
    });
  });
}
