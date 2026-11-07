import 'package:docasa_app/data/filter_health.dart';
import 'package:docasa_app/protocol/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const budgets =
      FilterBudgets(); // dirty budget 5,300 h (D-037/D-038), load 540e9
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
          counters: counters(dirtySec: budgets.dirtyAirSecondsBudget ~/ 2),
          budgets: budgets,
          now: now);
      expect(h.pct, closeTo(50, 0.5));
    });

    test('over-budget clamps at 0%', () {
      final h = computeFilterHealth(
          counters: counters(dirtySec: budgets.dirtyAirSecondsBudget * 2),
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
          counters:
              counters(dirtySec: budgets.dirtyAirSecondsBudget ~/ 40),
          budgets: budgets,
          now: now,
          dirtyRatePerDaySec: 10 * 3600);
      // 97.5% of the 5,300-h budget left at 10 h/day → 516.75 → 517 days.
      expect(h.remainingDays, 517);
      expect(h.projectedReplacement!.isAfter(now), isTrue);
    });

    test('D-037/D-038 calibration — fresh reset projects inside the '
        '6–10 month band at the exposure-model rate', () {
      // The seeded/all-day exposure model: ≈92 % of a full day is POOR+
      // (79,488 s/day) with a freshly reset baseline at Normal ×1.0.
      final h = computeFilterHealth(
          counters: counters(dirtySec: 0),
          budgets: budgets,
          now: now,
          dirtyRatePerDaySec: 79_488);
      expect(h.pct, 100);
      expect(h.remainingDays, inExclusiveRange(180, 299),
          reason: '6–10 months of filter life at Normal after a reset');
    });
  });

  group('sensitivity multiplies the budget (both bases)', () {
    test('sensitive halved budget → double consumption', () {
      final relaxed = computeFilterHealth(
          counters: counters(dirtySec: budgets.dirtyAirSecondsBudget ~/ 2),
          budgets: budgets,
          now: now,
          sensitivity: FilterSensitivity.relaxed);
      final sensitive = computeFilterHealth(
          counters: counters(dirtySec: budgets.dirtyAirSecondsBudget ~/ 2),
          budgets: budgets,
          now: now,
          sensitivity: FilterSensitivity.sensitive);
      expect(sensitive.pct, lessThan(relaxed.pct));
      // Half the budget against ×1.5 (7,950 h) → 66.7%; against ×0.5
      // (2,650 h) → 0%.
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
