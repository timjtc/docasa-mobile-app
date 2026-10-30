import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../data/filter_health.dart';
import '../../providers.dart';

/// Filter health — % of life left, projection, raw counters, budget config.
/// Reset flow is UI-gated until Phase 5 (security ruling D-010).
class FilterPage extends ConsumerStatefulWidget {
  const FilterPage({super.key});

  @override
  ConsumerState<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends ConsumerState<FilterPage> {
  late final TextEditingController _hourCtrl;
  late final TextEditingController _loadCtrl;

  @override
  void initState() {
    super.initState();
    final b = ref.read(settingsProvider).budgets;
    _hourCtrl = TextEditingController(text: b.hourBudgetRpmS.toString());
    _loadCtrl = TextEditingController(
        text: b.loadBudgetRpmUgS.toString());
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _loadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final counters =
        ref.watch(filterCountersProvider).value;
    final health = ref.watch(filterHealthProvider).value;
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
          _budgetCard(cs),
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
                'How this is estimated: the purifier accumulates fan usage '
                'weighted by particulate load (PM2.5). This is the same '
                'load-model used by commercial purifiers — an estimate, not a '
                'direct measurement. A dusty environment genuinely consumes '
                'filter life faster. VOC is a qualitative proxy and does not '
                'affect the estimate.',
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
                h.loadBinding
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

  Widget _budgetCard(ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter model budgets',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 4),
            Text(
              'Defaults are placeholders (D-011) — ~3000 h @ 2000 RPM with a '
              '25 µg/m³ average load. Replace with the real filter model\'s '
              'ratings when known.',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _hourCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Hour budget (RPM·s)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _loadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Load budget (RPM·µg·s)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: _saveBudgets,
                child: const Text('Save budgets'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBudgets() async {
    final hour = int.tryParse(_hourCtrl.text.trim());
    final load = int.tryParse(_loadCtrl.text.trim());
    if (hour == null || load == null || hour <= 0 || load <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budgets must be positive integers')),
        );
      }
      return;
    }
    final s = ref.read(settingsProvider);
    await ref
        .read(settingsProvider.notifier)
        .update(s.copyWith(budgets: FilterBudgets(hourBudgetRpmS: hour, loadBudgetRpmUgS: load)));
    ref.invalidate(filterHealthProvider);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Budgets saved')));
    }
  }

  static Color _healthColor(double? pct) {
    if (pct == null) return Colors.grey;
    if (pct > 50) return const Color(0xFF4CAF50);
    if (pct > 20) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }
}
