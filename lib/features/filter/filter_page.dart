import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/filter_health.dart';
import '../../data/settings_repository.dart';
import '../../providers.dart';

/// Filter health — % of life left, projection, sensitivity, and the manual
/// "I replaced the filter" reset (D-036). Raw device counters moved to the
/// Device tab behind dev options; the replacement basis is pinned to
/// dirty-air hours for consumers — switching lives in Developer options.
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
          else _healthCard(health),
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
                  FilledButton.icon(
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('I replaced the filter'),
                    onPressed: _confirmReplaceFilter,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Once you have physically swapped in the new filter '
                    'cartridge, tap the button above — the filter-life '
                    'estimate starts over from a fresh 100%.',
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
                    ? 'Not enough recorded usage yet to estimate the '
                        'remaining filter life'
                    : '${_friendlyLeft(h.remainingDays!)} · based on recent '
                        'usage',
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

  Widget _sensitivityCard(ColorScheme cs, FilterSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              'Sliding toward Sensitive means the filter will need to be '
              'replaced sooner; sliding toward Relaxed means it will last '
              'longer. Normal keeps the estimate balanced.',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  /// Manual replacement (D-036): a plain confirmation prompt first, then the
  /// same reset the alert modal's replacement action performs.
  Future<void> _confirmReplaceFilter() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Did you replace the filter?'),
        content: const Text(
          'Confirming will reset what the purifier has recorded about the '
          'filter’s usage, and it will start tracking the filter’s usage '
          'again from this point on.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yes, filter replaced'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(connectionProvider).resetFilter();
    ref.invalidate(filterCountersProvider);
    ref.invalidate(filterHealthProvider);
    final s = ref.read(settingsProvider);
    await ref
        .read(settingsProvider.notifier)
        .update(s.copyWith(lastAlertMs: 0));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Filter life reset — enjoy the new filter'),
        duration: Duration(seconds: 2),
      ));
    }
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

  /// Human-facing remaining-life text (user request 2026-11-09): approximate
  /// months above ~6 weeks, days below that — no calendar dates.
  String _friendlyLeft(int days) {
    if (days < 46) return 'About $days days left';
    final months = (days / 30.4).round();
    return 'About $months month${months == 1 ? '' : 's'} left';
  }

  static Color _healthColor(double? pct) {
    if (pct == null) return Colors.grey;
    if (pct > 50) return const Color(0xFF4CAF50);
    if (pct > 20) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }
}
