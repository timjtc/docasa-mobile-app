import 'package:drift/drift.dart';

import 'db/database.dart';

/// Raw → minute → hour aggregation with retention pruning.
///
/// D-012 policy (resolved 2026-10-30): raw 1 Hz kept **24 h** → 1-minute
/// aggregates kept **7 d** → 1-hour aggregates kept **90 d** (risk 7.21).
/// Partial edge buckets are recomputed on every run (INSERT OR REPLACE), so
/// counts settle as data arrives.
class HistoryCompactor {
  const HistoryCompactor();

  static const int rawRetentionMs = 24 * 3600 * 1000;
  static const int minuteRetentionMs = 7 * 24 * 3600 * 1000;
  static const int hourRetentionMs = 90 * 24 * 3600 * 1000;

  /// Runs one full compaction pass. [nowMs] injectable for tests.
  Future<void> run(AppDatabase db, {int? nowMs}) async {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;

    // 1) Refresh minute aggregates over the raw retention window.
    await db.customUpdate(_minuteAggSql,
        variables: [Variable.withInt(now - rawRetentionMs - 60000)]);

    // 2) Refresh hour aggregates from minute aggregates (weighted by counts).
    await db.customUpdate(_hourAggSql,
        variables: [Variable.withInt(now - minuteRetentionMs - 60000)]);

    // 3) Prune by retention policy.
    await db.customUpdate('DELETE FROM raw_samples WHERE time_ms < ?',
        variables: [Variable.withInt(now - rawRetentionMs)]);
    await db.customUpdate(
        'DELETE FROM minute_aggregates WHERE minute_start_ms < ?',
        variables: [Variable.withInt(now - minuteRetentionMs)]);
    await db.customUpdate(
        'DELETE FROM hour_aggregates WHERE hour_start_ms < ?',
        variables: [Variable.withInt(now - hourRetentionMs)]);
  }

  static const String _avgCols =
      'pm1, pm25, pm10, temp, humidity, voc, fan_rpm, battery_pct, battery_v';

  static const String _minuteAggSql = '''
INSERT OR REPLACE INTO minute_aggregates
  (minute_start_ms, $_avgCols, stage_max,
   stage1_count, stage2_count, stage3_count, stage4_count, stage5_count,
   sample_count)
SELECT (time_ms / 60000) * 60000,
       AVG(pm1), AVG(pm25), AVG(pm10), AVG(temp), AVG(humidity), AVG(voc),
       AVG(fan_rpm), AVG(battery_pct), AVG(battery_v),
       MAX(stage),
       SUM(CASE WHEN stage = 1 THEN 1 ELSE 0 END),
       SUM(CASE WHEN stage = 2 THEN 1 ELSE 0 END),
       SUM(CASE WHEN stage = 3 THEN 1 ELSE 0 END),
       SUM(CASE WHEN stage = 4 THEN 1 ELSE 0 END),
       SUM(CASE WHEN stage = 5 THEN 1 ELSE 0 END),
       COUNT(*)
FROM raw_samples
WHERE time_ms >= ?
GROUP BY time_ms / 60000''';

  static const String _hourAggSql = '''
INSERT OR REPLACE INTO hour_aggregates
  (hour_start_ms, $_avgCols, stage_max,
   stage1_count, stage2_count, stage3_count, stage4_count, stage5_count,
   sample_count)
SELECT (minute_start_ms / 3600000) * 3600000,
       SUM(pm1 * sample_count) / SUM(sample_count),
       SUM(pm25 * sample_count) / SUM(sample_count),
       SUM(pm10 * sample_count) / SUM(sample_count),
       SUM(temp * sample_count) / SUM(sample_count),
       SUM(humidity * sample_count) / SUM(sample_count),
       SUM(voc * sample_count) / SUM(sample_count),
       SUM(fan_rpm * sample_count) / SUM(sample_count),
       SUM(battery_pct * sample_count) / SUM(sample_count),
       SUM(battery_v * sample_count) / SUM(sample_count),
       MAX(stage_max),
       SUM(stage1_count), SUM(stage2_count), SUM(stage3_count),
       SUM(stage4_count), SUM(stage5_count),
       SUM(sample_count)
FROM minute_aggregates
WHERE minute_start_ms >= ?
GROUP BY minute_start_ms / 3600000''';
}

/// Convenience: delete all recorded history (demo "clear" tool).
Future<void> wipeHistory(AppDatabase db) async {
  await db.customUpdate('DELETE FROM hour_aggregates');
  await db.customUpdate('DELETE FROM minute_aggregates');
  await db.customUpdate('DELETE FROM raw_samples');
}
