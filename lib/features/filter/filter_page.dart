import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../data/filter_health.dart';
import '../../data/settings_repository.dart';
import '../../providers.dart';

/// Filter health — % of life left, projection, raw counters, sensitivity.
/// Basis toggle = dirty-air hours (default) vs load integral (D-027).
class FilterPage extends ConsumerStatefulWidget {
  const FilterPage({super.key});

  @override
  ConsumerState<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends ConsumerState<FilterPage> {
  @override
  Widget build(BuildContext context) {
    final counters =
        ref.watch(filterCountersProvider).value;
    final health = ref.watch(filterHealthProvider).value;
    final settings = ref.watch(settingsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('FILTER')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (counters == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Connect the device to read filter counters.'),
              ),
            )
          else ...[
            _healthCard(health),
            const SizedBox(height: 12),
            _countersCard(counters),
          ],
          const SizedBox(height: 12),
          _sensitivityCard(cs, settings),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Replace filter',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: cs.onSurface)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset filter counters'),
                    onPressed: null, // Phase 5 — security-gated (D-010)
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enabled in Phase 5, after the write-security ruling. The '
                    'device command zeroes the usage integrals only (powered '
                    'hours are preserved).',
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                settings.basis == FilterBasis.dirtyAir
                    ? 'How this is estimated: hours of time spent in dirty air '
                        '(POOR/BAD/HAZARD) since the last filter replacement '
                        'cross the exposure budget — a simple, explainable '
                        'replacement rule. Adjust it with the sensitivity '
                        'scale above.'
                    : 'How this is estimated: the purifier accumulates fan '
                        'usage weighted by particulate load (PM2.5) — the '
                        'same load model used by commercial purifiers. An '
                        'estimate, not a direct measurement. VOC is a '
                        'qualitative proxy and does not affect it.',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthCard(FilterHealth? h) {
    final cs = Theme.of(context).colorScheme;
    final pct = h?.pct;
    final color = _healthColor(pct);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              pct == null ? '—' : '${pct.toStringAsFixed(0)}%',
              style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
            Text('FILTER LIFE',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            if (h != null) ...[
              Text(
                h.remainingDays == null
                    ? 'Not enough history yet to project a replacement date'
                    : 'Projected replacement: ${DateFormat.yMMMd().format(h.projectedReplacement!)} '
                        '(${h.remainingDays} days at recent usage)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                h.basis == FilterBasis.dirtyAir
                    ? 'Consumption driven by dirty-air exposure time'
                    : h.loadBinding
                        ? 'Consumption driven by air load (PM-weighted)'
                        : 'Consumption driven by run hours',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: pct == null ? null : (pct / 100).clamp(0.0, 1.0),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _countersCard(dynamic counters) {
    final cs = Theme.of(context).colorScheme;
    final st = counters.stageSeconds as List<int>? ?? const <int>[];
    final dirtyH =
        counters.dirtyAirSeconds / 3600.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Device counters (raw)',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _row('Fan usage', Fmt.fanSecondsAsHours(counters.fanSeconds),
                'equivalent full-speed hours @ 4000 RPM'),
            _row('PM-weighted load', Fmt.bigInt(counters.pmWeightedFanSeconds),
                'RPM·µg·s integral'),
            if (st.length >= 5) ...[
              _row('Dirty-air time',
                  '${dirtyH.toStringAsFixed(1)} h',
                  'POOR/BAD/HAZARD since replacement (basis for health)'),
              _row('Time share per stage',
                  st.indexed.map((e) => '${e.$2}s').join(' · '),
                  'device stages GOOD…HAZARD (§4.4 "st")'),
            ],
            _row('Powered on', Fmt.powerOnHours(counters.powerOnHours),
                'device lifecycle — never reset'),
            const Divider(),
            Text(
              'Counters are stored on the device (NVS) and survive power '
              'cycles. Read on connect and every few minutes while connected.',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, String subtitle) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 10, color: Colors.white54)),
              ],
            ),
          ],
        ),
      );

  Widget _sensitivityCard(ColorScheme cs, FilterSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Replacement basis',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 8),
            SegmentedButton<FilterBasis>(
              segments: const [
                ButtonSegment(
                    value: FilterBasis.dirtyAir,
                    label: Text('Dirty-air hours')),
                ButtonSegment(
                    value: FilterBasis.load, label: Text('Load (µg·h)')),
              ],
              selected: {settings.basis},
              onSelectionChanged: (s) => _updateSetting(
                  (x) => x.copyWith(basis: s.first)),
            ),
            const SizedBox(height: 12),
            Text('Filter sensitivity',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 4),
            Slider(
              value: FilterSensitivity.values
                  .indexOf(settings.sensitivity)
                  .toDouble(),
              min: 0,
              max: FilterSensitivity.values.length - 1.toDouble(),
              divisions: FilterSensitivity.values.length - 1,
              label: FilterSensitivity.values
                  .indexOf(settings.sensitivity)
                  .toString(),
              onChanged: (v) => _updateSetting(
                (x) => x.copyWith(
                    sensitivity: FilterSensitivity.values[v.round()]),
              ),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Relaxed', style: TextStyle(fontSize: 11)),
                Text('Normal', style: TextStyle(fontSize: 11)),
                Text('Sensitive', style: TextStyle(fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Applies to both bases — sliding toward Sensitive spends the '
              'budget faster (scales the budget ×'
              '${settings.sensitivity.multiplier}); the replacement date '
              'moves sooner/later accordingly. Placeholder budget numbers '
              '(D-011) stay code-side.',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateSetting(
      FilterSettings Function(FilterSettings) f) async {
    final s = ref.read(settingsProvider);
    final before = s.sensitivity;
    final after = f(s).sensitivity;
    await ref
        .read(settingsProvider.notifier)
        .update(f(s));
    ref.invalidate(filterHealthProvider);
    // D-030 demo requirement: a Sensitive setting under the seeded story
    // must land at 0% and prompt the replacement modal IMMEDIATELY (the
    // 5-min evaluation timer otherwise waits too long for the panel).
    if (after != before) {
      await ref.read(recordingServiceProvider).evaluateNow();
    }
  }

  static Color _healthColor(double? pct) {
    if (pct == null) return Colors.grey;
    if (pct > 50) return const Color(0xFF4CAF50);
    if (pct > 20) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }
}
