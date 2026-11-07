import 'package:docasa_app/data/filter_health.dart';
import 'package:docasa_app/protocol/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const budgets =
      FilterBudgets(); // dirty budget 4,000 h (D-037), load 540e9
  final now = DateTime(2026, 11, 5);

  FilterCounters counters({int dirtySec = 0, int pwfs = 0, int fs = 0}) =>
      FilterCounters(
        fanSeconds: fs,
        pmWeightedFanSeconds: pwfs,
        powerOnHours: 0,
        stageSeconds: [
          0, 0, (dirtySec * 0.5).round(), //
          (dirtySec * 0.3).round(), (dirtySec * 0.2).round(),
        ],
      );

  group('dirty-air basis (D-027, installed default)', () {
    test('fresh/no dirty exposure → 100%', () {
      final h = computeFilterHealth(
          counters: counters(), budgets: budgets, now: now);
      expect(h.basis, FilterBasis.dirtyAir);
      expect(h.pct, 100);
    });

    test('50% of the dirty budget → 50%', () {
      final h = computeFilterHealth(
          counters: counters(dirtySec: 2000 * 3600),
          budgets: budgets,
          now: now);
      expect(h.pct, closeTo(50, 0.5));
    });

    test('over-budget clamps at 0%', () {
      final h = computeFilterHealth(
          counters: counters(dirtySec: 8000 * 3600),
          budgets: budgets,
          now: now);
      expect(h.pct, 0);
    });

    test('missing "st" (pre-v1.1 firmware) → neutral 100% (X7 fallback)', () {
      final c = FilterCounters(fanSeconds: 0, pmWeightedFanSeconds: 0, powerOnHours: 5);
      final h = computeFilterHealth(
          counters: c, budgets: budgets, now: now);
      expect(h.pct, 100);
      expect(c.dirtyAirSeconds, 0);
    });

    test('projection uses the dirty-air rate per day', () {
      final h = computeFilterHealth(
          counters: counters(dirtySec: 100 * 3600),
          budgets: budgets,
          now: now,
          dirtyRatePerDaySec: 10 * 3600);
      // budget − used = 3900 h at 10 h/day → 390 days.
      expect(h.remainingDays, 390);
      expect(h.projectedReplacement!.isAfter(now), isTrue);
    });

    test('D-037 calibration — fresh reset projects inside the 6–10 month '
        'band at the seeded exposure rate', () {
      // The demo story's dirty rate ≈ 16.4 h/day POOR+ (59,040 s/day);
      // a freshly reset filter projects ~8 months at Normal ×1.0.
      final h = computeFilterHealth(
          counters: counters(dirtySec: 0),
          budgets: budgets,
          now: now,
          dirtyRatePerDaySec: 59_040);
      expect(h.pct, 100);
      expect(h.remainingDays, inExclusiveRange(180, 299),
          reason: '6–10 months of filter life at Normal after a reset');
    });
  });

  group('sensitivity multiplies the budget (both bases)', () {
    test('sensitive halved budget → double consumption', () {
      final relaxed = computeFilterHealth(
          counters: counters(dirtySec: 2000 * 3600),
          budgets: budgets,
          now: now,
          sensitivity: FilterSensitivity.relaxed);
      final sensitive = computeFilterHealth(
          counters: counters(dirtySec: 2000 * 3600),
          budgets: budgets,
          now: now,
          sensitivity: FilterSensitivity.sensitive);
      expect(sensitive.pct, lessThan(relaxed.pct));
      // 2000 h against 6000 h (relaxed) → 66.7%; against 2000 h → 0%.
      expect((relaxed.pct - (2 / 3) * 100).abs(), lessThan(0.5));
      expect(sensitive.pct, closeTo(0, 0.001));
    });

    test('load basis with sensitivity scales pwfs budget', () {
      final h = computeFilterHealth(
          counters: counters(
              pwfs: (budgets.loadBudgetRpmUgS * 0.75).toInt()),
          budgets: budgets,
          now: now,
          basis: FilterBasis.load,
          sensitivity: FilterSensitivity.relaxed);
      // 0.75× of the load budget vs budget×1.5 = 0.5 consumptex → 50%.
      expect(h.pct, closeTo(50, 0.001));
      expect(h.loadBinding, isTrue);
    });
  });
}
