import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/history_compactor.dart';
import '../../data/history_seeder.dart';
import '../../providers.dart';
import '../../protocol/models.dart';
import '../shared/widgets.dart';
import '../filter/filter_alert_modal.dart';
import 'device_picker.dart';

/// Connection manager + device info + Phase 3 demo tools.
class DevicePage extends ConsumerWidget {
  const DevicePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(connectionProvider);
    final state = ref.watch(connectionStateProvider).value ??
        DocasaConnectionState.disconnected;
    final info = ref.watch(deviceInfoProvider).value;
    final counters = ref.watch(filterCountersProvider).value;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DEVICE'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ConnectionChip(state),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          switch (state) {
                            DocasaConnectionState.connected =>
                              'Connected to DOCASA-AirPurifier',
                            DocasaConnectionState.connecting =>
                              'Connecting…',
                            DocasaConnectionState.disconnected =>
                              'No device connected',
                          },
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: state == DocasaConnectionState.connected
                            ? () => conn.disconnect()
                            : null,
                        child: const Text('Disconnect'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        icon: const Icon(Icons.bluetooth),
                        label: Text(state == DocasaConnectionState.connected ? 'Reconnect' : 'Connect'),
                        onPressed: state == DocasaConnectionState.connected
                            ? () async {
                                await conn.disconnect();
                                if (!context.mounted) return;
                                await startConnectFlow(context, ref);
                              }
                            : () => startConnectFlow(context, ref),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: cs.primaryContainer.withValues(alpha: 0.3),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.science_outlined, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      kRealBle
                          ? 'Real transport (flutter_blue_plus) — runtime '
                              'verification at G4 after the bench session.'
                          : 'Phase 3: connected to the built-in device emulator '
                              '— same protocol path as real BLE.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (info != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Device information',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _kv('Manufacturer', info.manufacturer),
                    _kv('Model', info.model),
                    _kv('Firmware', info.firmwareRevision),
                    _kv('Hardware', info.hardwareRevision),
                    _kv('Protocol', 'v1 (JSON)'),
                    _kv('Time sync', 'sent on every connect'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (counters != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Filter counters',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _kv('Fan usage', Fmt.fanSecondsAsHours(counters.fanSeconds)),
                    _kv('PM-weighted load',
                        Fmt.bigInt(counters.pmWeightedFanSeconds)),
                    _kv('Powered on', Fmt.powerOnHours(counters.powerOnHours)),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => ref.invalidate(filterCountersProvider),
                        child: const Text('Refresh'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Demo data (Phase 3)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    'Backfill a week of simulated history (device "off" '
                    'overnight) to exercise the day/week/month charts, or '
                    'clear all recorded history.',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Clear history'),
                        onPressed: () async {
                          await wipeHistory(ref.read(dbProvider));
                          ref.read(historyEpochProvider.notifier).bump();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Seed 7 days'),
                        onPressed: () async {
                          await const HistorySeeder()
                              .seed(ref.read(dbProvider), days: 7);
                          ref.read(historyEpochProvider.notifier).bump();
                        },
                      ),
                    ],
                  ),
                  // Demo-only alert preview (user requirement): raises the
                  // replacement modal without waiting for real degradation.
                  // Hidden in the prod transport (kRealBle).
                  if (!kRealBle) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.warning_amber_outlined),
                          label: const Text('Preview filter alert'),
                          onPressed: () => requestFilterAlertModal(ref),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(k)),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
