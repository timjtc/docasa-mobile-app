import 'package:drift/drift.dart';

import '../protocol/contract.dart';
import 'db/database.dart';

enum HistoryRange {
  day(24 * 3600 * 1000, 60 * 1000, 'minute_aggregates', 'minute_start_ms'),
  week(7 * 24 * 3600 * 1000, 3600 * 1000, 'hour_aggregates', 'hour_start_ms'),
  month(30 * 24 * 3600 * 1000, 3600 * 1000, 'hour_aggregates', 'hour_start_ms');

  const HistoryRange(this.windowMs, this.bucketMs, this.table, this.startCol);

  final int windowMs;
  final int bucketMs;
  final String table;
  final String startCol;
}

enum HistoryMetric {
  pm25('pm25', 'PM2.5', ' µg/m³'),
  pm10('pm10', 'PM10', ' µg/m³'),
  pm1('pm1', 'PM1.0', ' µg/m³'),
  temp('temp', 'Temperature', ' °C'),
  humidity('humidity', 'Humidity', ' %'),
  voc('voc', 'VOC', ' kΩ'),
  fanRpm('fan_rpm', 'Fan', ' RPM'),
  batteryPct('battery_pct', 'Battery', ' %');

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
    final windowStart = _floor(now - range.windowMs, range.bucketMs);
    final bucketCount = (now - windowStart) ~/ range.bucketMs;

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

  static int _floor(int ms, int bucket) => ms - ms % bucket;
}
