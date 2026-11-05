import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/stage.dart';
import '../../data/history_repository.dart';
import '../../providers.dart';

/// History — day/week/month charts with gap breaks + stage distribution donut
/// (required feature 2; app-recorded while connected until Phase 5).
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  HistoryRange _range = HistoryRange.day;
  HistoryMetric _metric = HistoryMetric.pm25;

  @override
  Widget build(BuildContext context) {
    final series = ref.watch(historyProvider((_range, _metric))).value;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HISTORY'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(historyEpochProvider.notifier).bump(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SegmentedButton<HistoryRange>(
            segments: const [
              ButtonSegment(value: HistoryRange.day, label: Text('Day')),
              ButtonSegment(value: HistoryRange.week, label: Text('Week')),
              ButtonSegment(value: HistoryRange.month, label: Text('Month')),
            ],
            selected: {_range},
            onSelectionChanged: (s) => setState(() => _range = s.first),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${_metric.label} (${_metric.unit.trim()})',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      DropdownButton<HistoryMetric>(
                        value: _metric,
                        underline: const SizedBox.shrink(),
                        items: [
                          for (final m in HistoryMetric.values)
                            DropdownMenuItem(value: m, child: Text(m.label)),
                        ],
                        onChanged: (m) =>
                            setState(() => _metric = m ?? _metric),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 220,
                    child: series == null || series.isEmpty
                        ? Center(
                            child: Text(
                              'No recorded data in this window yet.\n'
                              'Data is recorded while the app is connected.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          )
                        : _chart(series, cs),
                  ),
                  if (series != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Coverage: ${Fmt.coveragePct(series.coverage)} of window · '
                        'gaps shown as line breaks',
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (series != null && !series.isEmpty) _donutCard(series),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'History is recorded by the app while connected to the purifier. '
                'Offline periods (device off or out of range) appear as gaps — '
                'they are captured on-device from Phase 5.',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chart(HistorySeries s, ColorScheme cs) {
    final xs = s.windowStartMs.toDouble();
    final xe = xs + s.bucketCount * s.range.bucketMs;
    final ys = <double>[
      for (final p in s.points)
        ?p,
    ];
    var minY = 0.0;
    var maxY = 1.0;
    if (ys.isNotEmpty) {
      minY = ys.reduce((a, b) => a < b ? a : b);
      maxY = ys.reduce((a, b) => a > b ? a : b);
      if (maxY - minY < 1e-6) maxY = minY + 1;
      final pad = (maxY - minY) * 0.1;
      minY = (minY - pad).clamp(0, minY);
      maxY += pad;
    }

    final yInterval = _nice((maxY - minY) / 4);
    final xInterval =
        (s.range.windowMs / 6).toDouble(); // ~6 bottom labels

    return LineChart(
      LineChartData(
        minX: xs,
        maxX: xe,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: [
              // Gap marker MUST be FlSpot.nullSpot — a FlSpot(x, NaN) with a
              // real x fails spot.isNull()'s nullSpot-equality (FlSpot ==
              // only matches NaN on BOTH axes), the segments never split and
              // the stroke path silently breaks (invisible line).
              for (var i = 0; i < s.bucketCount; i++)
                s.points[i] == null
                    ? FlSpot.nullSpot
                    : FlSpot(
                        xs + i * s.range.bucketMs, s.points[i]!),
            ],
            color: cs.primary,
            barWidth: 1.6,
            dotData: const FlDotData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: yInterval == 0 ? 1 : yInterval,
              getTitlesWidget: (v, m) =>
                  Text(v.toStringAsFixed(0), style: _axisStyle),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: xInterval,
              getTitlesWidget: (v, m) => Text(
                _xLabel(v),
                style: _axisStyle,
              ),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        // Theme-paired tooltip bubble: fl_chart's default is dark, with text
        // tinted the line color (pale in light mode → unreadable, D-026).
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => cs.primaryContainer,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  s.y.toString(),
                  TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle get _axisStyle => TextStyle(
      fontSize: 10,
      // Theme-derived: white54 was invisible on the light theme card (D-026).
      color: Theme.of(context).colorScheme.onSurfaceVariant);

  String _xLabel(double ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms.toInt());
    return switch (_range) {
      HistoryRange.day => DateFormat.Hm().format(d),
      HistoryRange.week => DateFormat.E().format(d),
      HistoryRange.month => DateFormat.Md().format(d),
    };
  }

  Widget _donutCard(HistorySeries s) {
    final cs = Theme.of(context).colorScheme;
    final total = s.stageCounts.fold<int>(0, (a, b) => a + b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Air quality time share',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: [
                        for (var i = 0; i < 5; i++)
                          if (s.stageCounts[i] > 0)
                            PieChartSectionData(
                              value: s.stageCounts[i].toDouble(),
                              color: AirStage.values[i].color,
                              radius: 24,
                              title:
                                  '${(s.stageCounts[i] * 100 / total).toStringAsFixed(0)}%',
                              titleStyle: const TextStyle(
                                  fontSize: 10, color: Colors.black),
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      for (var i = 0; i < 5; i++)
                        if (s.stageCounts[i] > 0)
                          _legendRow(
                            AirStage.values[i],
                            '${Fmt.bigInt(s.stageCounts[i] ~/ 60)} min',
                          ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Share of recorded time per stage (device 5-level scale)',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(AirStage stage, String trailing) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: stage.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(stage.label),
            const Spacer(),
            Text(trailing),
          ],
        ),
      );

  static double _nice(double v) {
    if (v <= 0) return 1;
    final mag = _pow10((v).toStringAsFixed(0).length - 1);
    return (v / mag).ceil() * mag;
  }

  static double _pow10(int e) {
    var r = 1.0;
    for (var i = 0; i < e; i++) {
      r *= 10;
    }
    return r;
  }
}
