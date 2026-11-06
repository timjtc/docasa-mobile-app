import 'package:drift/drift.dart';

import '../protocol/contract.dart';
import 'db/database.dart';

/// History range window kinds. `lastMonth` is calendar-bounded: the previous
/// complete month (the 1st of the last month → the 1st of this month) instead
/// of a sliding window (D-032).
enum HistoryRange {
  day(24 * 3600 * 1000, 60 * 1000, 'minute_aggregates', 'minute_start_ms'),
  week(7 * 24 * 3600 * 1000, 3600 * 1000, 'hour_aggregates', 'hour_start_ms'),
  month(30 * 24 * 3600 * 1000, 3600 * 1000, 'hour_aggregates', 'hour_start_ms'),
  lastMonth(31 * 24 * 3600 * 1000, 3600 * 1000, 'hour_aggregates',
      'hour_start_ms');

  const HistoryRange(this.windowMs, this.bucketMs, this.table, this.startCol);

  final int windowMs;
  final int bucketMs;
  final String table;
  final String startCol;

  /// Calendar-bounded (previous complete month) rather than sliding.
  bool get isCalendar => this == HistoryRange.lastMonth;
}

enum HistoryMetric {
  pm25('pm25', 'PM2.5', ' µg/m³'),
  pm10('pm10', 'PM10', ' µg/m³'),
  pm1('pm1', 'PM1.0', ' µg/m³'),
  temp('temp', 'Temperature', ' °C'),
  humidity('humidity', 'Humidity', ' %'),
  voc('voc', 'VOC', ' kΩ');
  // Fan and Battery graphs are retired from the History tab (D-032). The
  // seeded/recorder columns stay in the DB — it is a display filter only.

  const HistoryMetric(this.column, this.label, this.unit);

  final String column;
  final String label;
  final String unit;
}

/// One query result for a (range, metric) pair.
class HistorySeries {
  const HistorySeries({
    required this.range,
    required this.metric,
    required this.windowStartMs,
    required this.points,
    required this.stageCounts,
    required this.coverage,
  });

  final HistoryRange range;
  final HistoryMetric metric;

  /// First bucket start (window start floored to a bucket boundary).
  final int windowStartMs;

  /// Value per bucket, aligned from [windowStartMs]; `null` = no recorded
  /// data in that bucket (gap — rendered as a line break).
  final List<double?> points;

  /// Seconds per stage over the window (for the distribution donut), 1–5.
  final List<int> stageCounts;

  /// Recorded fraction of the window (0–1).
  final double coverage;

  int get bucketCount => points.length;
  bool get isEmpty => stageCounts.fold<int>(0, (a, b) => a + b) == 0;
}

class HistoryRepository {
  const HistoryRepository();

  /// Loads the series for [range]/[metric]. [nowMs] injectable for tests.
  Future<HistorySeries> load(
    AppDatabase db,
    HistoryRange range,
    HistoryMetric metric, {
    int? nowMs,
  }) async {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    int windowStart;
    int bucketCount;

    // D-032: `lastMonth` is the previous complete calendar month, hour-aligned.
    if (range.isCalendar) {
      final today = DateTime.fromMillisecondsSinceEpoch(now);
      final prevFirst = DateTime(today.year, today.month - 1, 1);
      final monthEnd = DateTime(today.year, today.month, 1);
      windowStart = _floor(
          prevFirst.millisecondsSinceEpoch, range.bucketMs);
      bucketCount =
          (monthEnd.millisecondsSinceEpoch - windowStart) ~/ range.bucketMs;
    } else {
      windowStart = _floor(now - range.windowMs, range.bucketMs);
      bucketCount = (now - windowStart) ~/ range.bucketMs;
    }

    final rows = await db.customSelect(
      'SELECT ${range.startCol} AS bucket, ${metric.column} AS value, '
      'sample_count, stage1_count, stage2_count, stage3_count, '
      'stage4_count, stage5_count '
      'FROM ${range.table} WHERE ${range.startCol} >= ? ORDER BY bucket',
      variables: [Variable.withInt(windowStart)],
    ).get();

    final byBucket = <int, double>{};
    var totalSamples = 0;
    final coveredBuckets = <int>{};
    final stageCounts = List<int>.filled(5, 0);

    for (final r in rows) {
      final bucket = r.read<int>('bucket');
      byBucket[bucket] = r.read<double>('value');
      totalSamples += r.read<int>('sample_count');
      coveredBuckets.add(bucket);
      for (var s = 1; s <= 5; s++) {
        stageCounts[s - 1] += r.read<int>('stage${s}_count');
      }
    }

    // v1.1 (D-028): device-side offline windows merge INTO bucket gaps — a
    // bucket the app recorded itself keeps its row; absent buckets receive
    // the window's PM2.5 mean and its proportional stage split, so the day/
    // week/month lines and the stage donut back-fill (record carries PM2.5
    // + stage seconds only — device-unmeasured metrics stay gaps).
    if (metric == HistoryMetric.pm25) {
      final winds = await db.customSelect(
        'SELECT window_start_ms, pm_mean, stage1_sec, stage2_sec, stage3_sec,'
        ' stage4_sec, stage5_sec FROM device_windows'
        ' WHERE window_start_ms < ? AND window_start_ms + 600000 > ?'
        ' ORDER BY window_start_ms',
        variables: [
          Variable.withInt(windowStart + bucketCount * range.bucketMs),
          Variable.withInt(windowStart),
        ],
      ).get();
      for (final w in winds) {
        final wStart = w.read<int>('window_start_ms');
        final st = [
          for (var i = 0; i < 5; i++) w.read<int>('stage${i + 1}_sec'),
        ];
        final windowTotal = st.fold<int>(0, (a, b) => a + b); // ≈600 s
        if (windowTotal <= 0) continue;
        final pmMean = w.read<double>('pm_mean');
        final lastMs = windowStart + bucketCount * range.bucketMs;
        var bStart = _floor(
          wStart > windowStart ? wStart : windowStart,
          range.bucketMs,
        );
        final wEndMs = wStart + DocasaContract.offlineWindowMs;
        while (bStart < lastMs && bStart < wEndMs) {
          if (!coveredBuckets.contains(bStart)) {
            var c0s = (bStart - wStart) ~/ 1000;
            if (c0s < 0) c0s = 0;
            var c1s = (bStart + range.bucketMs - wStart + 999) ~/ 1000;
            if (c1s > windowTotal) c1s = windowTotal;
            if (c1s > c0s) {
              byBucket[bStart] = pmMean;
              coveredBuckets.add(bStart);
              totalSamples += c1s - c0s;
              for (var s = 0; s < 5; s++) {
                stageCounts[s] +=
                    (st[s] * c1s / windowTotal - st[s] * c0s / windowTotal)
                        .round();
              }
            }
          }
          bStart += range.bucketMs;
        }
      }
    }

    final points = List<double?>.generate(
      bucketCount,
      (i) => byBucket[windowStart + i * range.bucketMs],
    );

    // A "full" bucket holds bucketMs/1000 one-Hz samples.
    final expectedSamples = bucketCount * (range.bucketMs ~/ 1000);
    final coverage = expectedSamples == 0
        ? 0.0
        : (totalSamples / expectedSamples).clamp(0.0, 1.0);

    return HistorySeries(
      range: range,
      metric: metric,
      windowStartMs: windowStart,
      points: points,
      stageCounts: stageCounts,
      coverage: coverage,
    );
  }

  /// Month-over-month comparative analytics (D-032). Reads the hour tier for
  /// the previous and the current calendar month: weighted-average PM2.5 and
  /// the per-stage time split (the same source the charts use, so the numbers
  /// reconcile with what's drawn). Null when a period has no data at all.
  Future<MonthCompare?> monthCompare(
    AppDatabase db, {
    int? nowMs,
  }) async {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final today = DateTime.fromMillisecondsSinceEpoch(now);
    final prevFirst =
        DateTime(today.year, today.month - 1, 1).millisecondsSinceEpoch;
    final monthFirst = DateTime(today.year, today.month, 1).millisecondsSinceEpoch;
    final prev = await _queryPeriod(db, prevFirst, monthFirst);
    final current = await _queryPeriod(db, monthFirst, now + 1);
    if (prev == null && current == null) return null;
    return MonthCompare(previous: prev, current: current);
  }

  static Future<MonthStats?> _queryPeriod(
    AppDatabase db,
    int startMs,
    int endMs,
  ) async {
    final rows = await db.customSelect(
      'SELECT SUM(pm25 * sample_count) AS pm, SUM(sample_count) AS samples, '
      'SUM(stage1_count) AS s1, SUM(stage2_count) AS s2, '
      'SUM(stage3_count) AS s3, SUM(stage4_count) AS s4, '
      'SUM(stage5_count) AS s5, COUNT(*) AS buckets '
      'FROM hour_aggregates WHERE hour_start_ms >= ? AND hour_start_ms < ?',
      variables: [Variable.withInt(startMs), Variable.withInt(endMs)],
    ).get();
    if (rows.isEmpty) return null;
    final r = rows.first;
    final samples = r.read<int>('samples');
    if (samples <= 0) return null;
    final pm = r.read<double>('pm');
    final st = [
      r.read<int>('s1'),
      r.read<int>('s2'),
      r.read<int>('s3'),
      r.read<int>('s4'),
      r.read<int>('s5'),
    ];
    return MonthStats(
      startMs: startMs,
      endMs: endMs,
      avgPm25: pm / samples,
      stageSeconds: st,
      recordedHours: r.read<int>('buckets'),
    );
  }

  static int _floor(int ms, int bucket) => ms - ms % bucket;
}

/// One calendar-period's aggregate stats for the month compare card (D-032).
class MonthStats {
  const MonthStats({
    required this.startMs,
    required this.endMs,
    required this.avgPm25,
    required this.stageSeconds,
    required this.recordedHours,
  });

  final int startMs;
  final int endMs;

  /// Weighted-average PM2.5 over the period (µg/m³).
  final double avgPm25;

  /// Seconds per contract stage (index 0 = GOOD … 4 = HAZARD).
  final List<int> stageSeconds;

  final int recordedHours;

  int get dirtySeconds => stageSeconds.length >= 5
      ? stageSeconds[2] + stageSeconds[3] + stageSeconds[4]
      : 0;

  int get cleanSeconds => stageSeconds.length >= 2
      ? stageSeconds[0] + stageSeconds[1]
      : 0;
}

class MonthCompare {
  const MonthCompare({required this.previous, required this.current});

  /// The previous complete calendar month; null when unrecorded.
  final MonthStats? previous;

  /// The running calendar month (up to now); null when unrecorded.
  final MonthStats? current;
}
