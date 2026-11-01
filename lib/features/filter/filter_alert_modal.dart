import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

/// Snapshot access point for the demo "Preview filter alert" button.
void requestFilterAlertModal(WidgetRef ref) {
  ref.read(filterModalEventsProvider.notifier).fire();
}

/// The replacement-warning modal (user requirements): gentle warning, two
/// options — defer (remembered, reminds ≤ once/day) or "replaced"
/// (zeroes the filter-health integrals, all counters fresh).
Future<void> showFilterReplaceModal(BuildContext context) => showDialog(
      context: context,
      builder: (_) => const _FilterReplaceDialog(),
    );

class _FilterReplaceDialog extends ConsumerWidget {
  const _FilterReplaceDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = ref.watch(filterHealthProvider).value?.pct;
    return AlertDialog(
      title: const Text('Filter needs replacing'),
      content: Text(
        pct == null
            ? 'Filter health has degraded past the threshold. Replace the '
                'filter as soon as possible.'
            : 'Filter health is at ${pct.round()}% — degraded past the '
                'threshold. Replace the filter as soon as possible.',
      ),
      actions: [
        TextButton(
          // Defer: RecordingService already stamped the daily-cap timestamp at
          // presentation; ack makes it an explicit "ignored" event so the
          // reminder (≤ 1/day while still degraded) behaves after reboots.
          onPressed: () async {
            final s = await ref.read(settingsRepoProvider).load();
            await ref
                .read(settingsRepoProvider)
                .save(s.copyWith(filterAlertAckMs: DateTime.now()
                        .millisecondsSinceEpoch));
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text("I'll replace it at a later time"),
        ),
        FilledButton(
          onPressed: () async {
            // Filter replaced → zero the usage integrals (user requirement +
            // Contract §5). NOTE: firmware v4.1.0 ignores this command until
            // the D-021 firmware change is flashed — app-side follow-up:
            // the providers below re-read whatever the device reports.
            await ref.read(connectionProvider).resetFilter();
            ref.invalidate(filterCountersProvider);
            ref.invalidate(filterHealthProvider);
            final s = await ref.read(settingsRepoProvider).load();
            await ref
                .read(settingsRepoProvider)
                .save(s.copyWith(lastAlertMs: 0));
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('I just replaced the filter'),
        ),
      ],
    );
  }
}
