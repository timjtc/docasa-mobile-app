import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ble/fake/fake_docasa_connection.dart';
import '../../ble/fbp/fbp_docasa_connection.dart';
import '../../core/format.dart';
import '../../data/history_compactor.dart';
import '../../data/history_seeder.dart';
import '../../providers.dart';
import '../../protocol/models.dart';
import '../shared/widgets.dart';
import '../filter/filter_alert_modal.dart';
import 'device_picker.dart';

/// Connection manager + device info + developer options (demo/dev tools,
/// D-030: hidden by default; enabled by tapping the Device information card
/// 7 times; disabled from a switch inside the section).
class DevicePage extends ConsumerStatefulWidget {
  const DevicePage({super.key});

  @override
  ConsumerState<DevicePage> createState() => _DevicePageState();
}

/// Tracks the 7-tap "Device information" pattern. Taps must land within
/// 2.5 s of each other or the counter resets.
class DevTapTracker {
  int count = 0;
  DateTime last = DateTime.fromMillisecondsSinceEpoch(0);

  /// Returns true exactly when the seventh consecutive quick tap lands
  /// (then resets, so a fresh run is needed to re-enable).
  bool tap() {
    final now = DateTime.now();
    if (now.difference(last) > const Duration(milliseconds: 2500)) count = 0;
    last = now;
    if (++count < 7) return false;
    count = 0;
    return true;
  }
}

class _DevicePageState extends ConsumerState<DevicePage> {
  final DevTapTracker _devTaps = DevTapTracker();

  void _onInfoCardTap() {
    if (ref.read(devOptionsProvider)) return; // already enabled
    if (_devTaps.tap()) {
      ref.read(devOptionsProvider.notifier).set(true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Developer options enabled'),
        duration: Duration(seconds: 2),
      ));
    }
  }

  Future<void> _seedTwoMonths() async {
    final conn = ref.read(connectionProvider);
    final connected =
        ref.read(connectionStateProvider).value == DocasaConnectionState.connected;
    if (!connected) {
      _snack('Connect the purifier first — seeding is pushed to the device');
      return;
    }
    final totals = await const TwoMonthSeeder().seed(ref.read(dbProvider));
    // Fresh filter story: reset the alert pipeline so the demo's replacement
    // prompt re-arms (D-021's daily cap would otherwise silence it).
    final s = ref.read(settingsProvider);
    await ref
        .read(settingsProvider.notifier)
        .update(s.copyWith(lastAlertMs: 0, filterAlertAckMs: 0));
    // Device counters adopt the seeded story (v1.1 §5 dev channel, D-030):
    // the real transport writes NVS over the air; the fake echoes into its
    // emulator state — either way the health basis reads "since replacement".
    try {
      if (conn is FbpDocasaConnection) {
        await conn.setUsage(
          fs: totals.fanSeconds,
          pwfs: totals.pmWeightedFanSeconds,
          onSeconds: totals.powerOnSeconds,
          stSeconds: totals.stageSeconds,
        );
      } else if (conn is FakeDocasaConnection) {
        await conn.setUsage(
          fs: totals.fanSeconds,
          pwfs: totals.pmWeightedFanSeconds,
          onSeconds: totals.powerOnSeconds,
          stSeconds: totals.stageSeconds,
        );
      }
    } on Exception {
      _snack('Seeded history — device counters not pushed (not a v4.2.1 device)');
    }
    ref.invalidate(filterCountersProvider);
    ref.invalidate(filterHealthProvider);
    ref.read(historyEpochProvider.notifier).bump();
    // D-030 demo requirement: with the seeded dirty story, setting the
    // sensitivity on the Filter page evaluates immediately; also prompt the
    // alert flow right after seeding (Sensitive → 0% → replacement modal).
    await ref.read(recordingServiceProvider).evaluateNow();
    _snack('Seeded 2 months — '
        '${totals.dirtySeconds ~/ 3600} h dirty air; device counters adopted');
  }

  void _snack(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text), duration: const Duration(seconds: 3)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final conn = ref.watch(connectionProvider);
    final state = ref.watch(connectionStateProvider).value ??
        DocasaConnectionState.disconnected;
    final info = ref.watch(deviceInfoProvider).value;
    final counters = ref.watch(filterCountersProvider).value;
    final devOptions = ref.watch(devOptionsProvider);
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
                        label: Text(state == DocasaConnectionState.connected
                            ? 'Reconnect'
                            : 'Connect'),
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
          if (info != null)
            Card(
              child: GestureDetector(
                onTap: _onInfoCardTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Device information',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _kv('Maker', info.manufacturer),
                      _kv('Model', info.model),
                      _kv('Firmware', info.firmwareRevision),
                      _kv('Hardware', info.hardwareRevision),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          // Raw device counters moved here from the Filter tab (user
          // request) and dev-gated — normal users see only health/sensitivity.
          if (counters != null && devOptions)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Device counters',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _kv('Fan usage', Fmt.fanSecondsAsHours(counters.fanSeconds),
                        'equivalent full-speed hours'),
                    _kv('PM-weighted load',
                        Fmt.bigInt(counters.pmWeightedFanSeconds),
                        'weighted particle-and-fan index'),
                    if (counters.stageSeconds.length >= 5) ...[
                      _kv('Dirty-air time',
                          '${(counters.dirtyAirSeconds / 3600.0).toStringAsFixed(1)} h',
                          'hours in POOR/BAD/HAZARD air since the filter swap'),
                      _kv('Time share per stage',
                          counters.stageSeconds.indexed
                              .map((e) => '${e.$2}s')
                              .join(' · '),
                          'seconds per air level the purifier measured'),
                    ],
                    _kv('Powered on', Fmt.powerOnHours(counters.powerOnHours),
                        'lifetime since first power-on'),
                    const Divider(),
                    Text(
                      'Counters live on the purifier and survive power '
                      'cycles. Read when the app connects and refreshed '
                      'while connected.',
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant),
                    ),
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
          if (devOptions)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Developer options',
                              style:
                                  TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Switch(
                          value: true,
                          onChanged: (_) =>
                              ref.read(devOptionsProvider.notifier).set(false),
                        ),
                      ],
                    ),
                    Text(
                      'Demo/dev tools. Re-seeding REPLACES the history '
                      'timeline and (on a connected v4.2.1 device) pushes '
                      'usage counters into the device NVS so the filter '
                      'story matches.',
                      style:
                          TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
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
                          label: const Text('Seed demo data (2 months)'),
                          onPressed: _seedTwoMonths,
                        ),
                      ],
                    ),
                    // Demo-only alert preview (D-021): raises the replacement
                    // modal without waiting for the seeded story.
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
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, [String? note]) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(k)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (note != null)
                  Text(note,
                      style: TextStyle(
                          fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      );
}
