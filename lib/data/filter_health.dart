import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../protocol/models.dart';
import 'db/database.dart';

/// Filter budgets — app-side configuration (Plan §4.2; the device stays
/// filter-model-agnostic). Placeholder defaults pending the real filter model
/// (Decision D-011): ~3000 h @ 2000 RPM, load budget equivalent to 25 µg/m³
/// average over the same hours. v1.1 (D-027): the dirty-air-hours basis uses
/// a 1000 h placeholder (≈ the 3000 h nominal at ~1/3 dirty-duty).
class FilterBudgets {
  const FilterBudgets({
    this.hourBudgetRpmS = 3000 * 2000 * 3600, // 21,600,000,000 RPM·s
    this.loadBudgetRpmUgS = 3000 * 2000 * 3600 * 25, // 540,000,000,000 RPM·µg·s
    this.dirtyAirSecondsBudget = 1000 * 3600, // 3,600,000 s of POOR+ air
  });

  /// Σ RPM·s before the pure-hours cap binds (secondary cap, Plan §4.2).
  final int hourBudgetRpmS;

  /// Σ RPM·µg·s before the load-weighted budget binds (primary signal).
  final int loadBudgetRpmUgS;

  /// Allowed POOR/BAD/HAZARD seconds before replacement (D-027).
  final int dirtyAirSecondsBudget;
}

/// Replacement basis the Filter page computes health with (D-027).
enum FilterBasis {
  /// Accumulated dirty-air time share — the installed default (D-027).
  dirtyAir,

  /// Original load integral (RPM·µg·s) with the pure-hours cap.
  load,
}

/// User-friendly sensitivity scale applied as a budget multiplier to BOTH
/// bases (D-027): larger multiplier = more allowed exposure = later
/// replacement. Replaces the old free-form budget text fields.
enum FilterSensitivity {
  relaxed(1.5, 'Relaxed (latest)'),
  normal(1.0, 'Normal (default)'),
  sensitive(0.5, 'Sensitive (sooner)');

  const FilterSensitivity(this.multiplier, this.label);
  final double multiplier;

  /// Display label.
  final String label;
}

class FilterHealth {
  const FilterHealth({
    required this.pct,
    required this.basis,
    required this.loadBinding,
    required this.remainingDays,
    required this.projectedReplacement,
  });

  /// 0–100.
  final double pct;

  /// Which basis produced this number (the page explains it per basis).
  final FilterBasis basis;

  /// True when the budget constraint binds (label meaning shifts per basis:
  /// dirty-air basis binds on exposure time; load basis on PM load vs hours).
  final bool loadBinding;

  /// Null when no rate estimate is available yet.
  final int? remainingDays;

  final DateTime? projectedReplacement;
}

/// Health by basis (D-027):
/// - `dirtyAir`: `1 − dirtySeconds / (dirtyBudget × sensitivity)`
/// - `load`:     `1 − pwfs/(loadBudget × sensitivity)`, capped by
///   `1 − fs/(hourBudget × sensitivity)`.
FilterHealth computeFilterHealth({
  required FilterCounters counters,
  required FilterBudgets budgets,
  required DateTime now,
  FilterBasis basis = FilterBasis.dirtyAir,
  FilterSensitivity sensitivity = FilterSensitivity.normal,
  double? loadRatePerDay,
  int? dirtyRatePerDaySec,
}) {
  final mult = sensitivity.multiplier;
  final double consumed;
  bool binding;
  int? remainingDays;
  switch (basis) {
    case FilterBasis.dirtyAir:
      final budget = (budgets.dirtyAirSecondsBudget * mult).round();
      final dirty = counters.dirtyAirSeconds;
      consumed = budget > 0 ? dirty / budget : 0.0;
      binding = true;
      if (dirtyRatePerDaySec != null && dirtyRatePerDaySec > 0) {
        remainingDays =
            ((budget - dirty) / dirtyRatePerDaySec).round().clamp(0, 100 * 365);
      }
    case FilterBasis.load:
      final loadFilc = budgets.loadBudgetRpmUgS > 0
          ? counters.pmWeightedFanSeconds / (budgets.loadBudgetRpmUgS * mult)
          : 0.0;
      final hourFrac = budgets.hourBudgetRpmS > 0
          ? counters.fanSeconds / (budgets.hourBudgetRpmS * mult)
          : 0.0;
      consumed = math.max(loadFilc, hourFrac);
      binding = loadFilc >= hourFrac;
      if (loadRatePerDay != null && loadRatePerDay > 0) {
        final remaining =
            budgets.loadBudgetRpmUgS * mult - counters.pmWeightedFanSeconds;
        remainingDays =
            (remaining / loadRatePerDay).round().clamp(0, 100 * 365);
      }
  }

  return FilterHealth(
    pct: (1 - consumed.clamp(0.0, 1.0)) * 100,
    basis: basis,
    loadBinding: binding,
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
  final n = rows.isEmpty ? 0 : rows.first.read<int>('n');
  final rate = rows.isEmpty ? null : rows.first.readNullable<double>('rate');
  if (n < 900 || rate == null || rate <= 0) return null;
  return rate * 86400;
}

/// Average daily dirty-air seconds (POOR/BAD/HAZARD share of connected rows,
/// scaled to a 24 h day) from recent raw history — the dirty-air basis's
/// projection source (D-027). Null under 15 min of data (recording only runs
/// while connected; Phase-5 back-fill lowers this bar).
Future<int?> estimateDirtyRatePerDay(
  AppDatabase db, {
  Duration window = const Duration(hours: 24),
  int? nowMs,
}) async {
  final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
  final rows = await db.customSelect(
    'SELECT COUNT(*) AS n, '
    'SUM(CASE WHEN stage >= 3 THEN 1 ELSE 0 END) AS dirty '
    'FROM raw_samples WHERE time_ms >= ?',
    variables: [Variable.withInt(now - window.inMilliseconds)],
  ).get();
  if (rows.isEmpty) return null;
  final n = rows.first.read<int>('n');
  final dirty = rows.first.readNullable<int>('dirty') ?? 0;
  if (n < 900) return null;
  return (dirty / n * 86400).round();
}
