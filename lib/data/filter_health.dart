import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../protocol/models.dart';
import 'db/database.dart';

/// Filter budgets — app-side configuration (Plan §4.2; the device stays
/// filter-model-agnostic). Placeholder defaults pending the real filter model
/// (Decision D-011): ~3000 h @ 2000 RPM, load budget equivalent to 25 µg/m³
/// average over the same hours.
class FilterBudgets {
  const FilterBudgets({
    this.hourBudgetRpmS = 3000 * 2000 * 3600, // 21,600,000,000 RPM·s
    this.loadBudgetRpmUgS = 3000 * 2000 * 3600 * 25, // 540,000,000,000 RPM·µg·s
  });

  /// Σ RPM·s before the pure-hours cap binds (secondary cap, Plan §4.2).
  final int hourBudgetRpmS;

  /// Σ RPM·µg·s before the load-weighted budget binds (primary signal).
  final int loadBudgetRpmUgS;
}

class FilterHealth {
  const FilterHealth({
    required this.pct,
    required this.loadBinding,
    required this.remainingDays,
    required this.projectedReplacement,
  });

  /// 0–100.
  final double pct;

  /// True when the PM-load budget is the binding constraint (vs pure hours).
  final bool loadBinding;

  /// Null when no rate estimate is available yet.
  final int? remainingDays;

  final DateTime? projectedReplacement;
}

/// Plan §4.2:
/// `health = 1 − pwfs/loadBudget`, capped by `1 − fs/hourBudget`.
FilterHealth computeFilterHealth({
  required FilterCounters counters,
  required FilterBudgets budgets,
  required DateTime now,
  double? loadRatePerDay,
}) {
  final loadFrac = budgets.loadBudgetRpmUgS > 0
      ? counters.pmWeightedFanSeconds / budgets.loadBudgetRpmUgS
      : 0.0;
  final hourFrac = budgets.hourBudgetRpmS > 0
      ? counters.fanSeconds / budgets.hourBudgetRpmS
      : 0.0;
  final consumed = math.max(loadFrac, hourFrac).clamp(0.0, 1.0);

  int? remainingDays;
  if (loadRatePerDay != null && loadRatePerDay > 0) {
    final remaining = budgets.loadBudgetRpmUgS - counters.pmWeightedFanSeconds;
    remainingDays =
        (remaining / loadRatePerDay).round().clamp(0, 100 * 365);
  }

  return FilterHealth(
    pct: (1 - consumed) * 100,
    loadBinding: loadFrac >= hourFrac,
    remainingDays: remainingDays,
    projectedReplacement: remainingDays == null
        ? null
        : now.add(Duration(days: remainingDays)),
  );
}

/// Average daily PM-load consumption from recent raw history
/// (RPM·µg·s per day). Null when there isn't enough recorded data (< 15 min)
/// — recording only happens while connected (Phase 3/4 reality).
Future<double?> estimateLoadRatePerDay(
  AppDatabase db, {
  Duration window = const Duration(hours: 24),
  int? nowMs,
}) async {
  final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
  final rows = await db.customSelect(
    'SELECT COUNT(*) AS n, AVG(fan_rpm * pm25) AS rate '
    'FROM raw_samples WHERE time_ms >= ?',
    variables: [Variable.withInt(now - window.inMilliseconds)],
  ).get();
  if (rows.isEmpty) return null;
  final n = rows.first.read<int>('n');
  final rate = rows.first.readNullable<double>('rate');
  if (n < 900 || rate == null || rate <= 0) return null;
  return rate * 86400;
}
