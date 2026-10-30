import 'package:flutter_test/flutter_test.dart';
import 'package:docasa_app/data/filter_health.dart';
import 'package:docasa_app/protocol/models.dart';

FilterCounters counters({int fs = 0, int pwfs = 0, int on = 0}) =>
    FilterCounters(fanSeconds: fs, pmWeightedFanSeconds: pwfs, powerOnHours: on);

void main() {
  const budgets = FilterBudgets();
  final now = DateTime(2026, 10, 30);

  test('fresh filter → 100%', () {
    final h = computeFilterHealth(
        counters: counters(), budgets: budgets, now: now);
    expect(h.pct, 100);
    expect(h.loadBinding, isTrue); // both fracs 0 → 0 >= 0 → load binds
  });

  test('monotonic: more PM-load consumption → lower health', () {
    final pcts = [
      for (final pwfs in [0, 1e10, 1e11, 2.7e11, 5.4e11])
        computeFilterHealth(
                counters: counters(pwfs: pwfs.toInt()),
                budgets: budgets,
                now: now)
            .pct
    ];
    for (var i = 1; i < pcts.length; i++) {
      expect(pcts[i], lessThan(pcts[i - 1]));
    }
    expect(pcts.last, 0); // exactly the load budget → 0%
  });

  test('pure-hours cap binds when air is clean (fs-only growth)', () {
    // 50% of the hour budget, ~0 load.
    final h = computeFilterHealth(
        counters: counters(fs: budgets.hourBudgetRpmS ~/ 2),
        budgets: budgets,
        now: now);
    expect(h.pct, closeTo(50, 0.001));
    expect(h.loadBinding, isFalse);
  });

  test('load cap binds in dirty air even with few hours', () {
    // Tiny fs, 80% of load budget.
    final h = computeFilterHealth(
        counters: counters(fs: 1000, pwfs: (budgets.loadBudgetRpmUgS * 0.8).toInt()),
        budgets: budgets,
        now: now);
    expect(h.pct, closeTo(20, 0.001));
    expect(h.loadBinding, isTrue);
  });

  test('reset (zero counters) → back to 100%', () {
    final spent = computeFilterHealth(
        counters: counters(fs: budgets.hourBudgetRpmS, pwfs: budgets.loadBudgetRpmUgS),
        budgets: budgets,
        now: now);
    expect(spent.pct, 0);
    final afterReset = computeFilterHealth(
        counters: counters(), budgets: budgets, now: now);
    expect(afterReset.pct, 100);
  });

  test('clamped uint64 extremes do not crash and floor at 0%', () {
    const huge = 9223372036854775807; // codec clamp ceiling (X-test)
    final h = computeFilterHealth(
        counters: counters(fs: huge, pwfs: huge), budgets: budgets, now: now);
    expect(h.pct, 0);
  });

  test('projection uses recent load rate; null rate → no projection', () {
    final noRate = computeFilterHealth(
        counters: counters(pwfs: 1e11.toInt()),
        budgets: budgets,
        now: now,
        loadRatePerDay: null);
    expect(noRate.remainingDays, isNull);
    expect(noRate.projectedReplacement, isNull);

    // Consumed 1e11 of 5.4e11; rate 1e10/day → 44 days left.
    final withRate = computeFilterHealth(
        counters: counters(pwfs: 1e11.toInt()),
        budgets: budgets,
        now: now,
        loadRatePerDay: 1e10);
    expect(withRate.remainingDays, 44);
    expect(withRate.projectedReplacement, now.add(const Duration(days: 44)));
  });

  test('projection floors at zero when over budget', () {
    final h = computeFilterHealth(
        counters: counters(pwfs: budgets.loadBudgetRpmUgS + 1),
        budgets: budgets,
        now: now,
        loadRatePerDay: 1e10);
    expect(h.pct, 0);
    expect(h.remainingDays, 0);
  });
}
