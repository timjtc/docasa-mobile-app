import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ble/fbp/fbp_docasa_connection.dart';
import '../../protocol/contract.dart';
import '../../providers.dart';

/// Connect entry point shared by the Device page and the offline Connect
/// prompt: real transport → device picker first (user picks by name, only
/// devices with a DOCASA-valid advertisement); emulator → direct connect.
Future<void> startConnectFlow(BuildContext context, WidgetRef ref) async {
  final conn = ref.read(connectionProvider);
  // Non-const local so the analyzer never prunes the real-transport branch.
  final bool realBle = kRealBle;
  if (!realBle || conn is! FbpDocasaConnection) {
    await conn.connect();
    return;
  }
  final dev = await showDevicePicker(context);
  if (dev != null) await conn.connectTo(dev);
}

/// Live scan picker (Contract §1 discovery): the primary list shows devices
/// whose advertisement carries the frozen DOCASA service UUID (or the exact
/// advertised name). When nothing valid shows up in the window, a diagnostic
/// section lists raw nearby advertisers (D-019: firmware ads are unverified).
Future<BluetoothDevice?> showDevicePicker(BuildContext context) =>
    showModalBottomSheet<BluetoothDevice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _DevicePickerSheet(),
    );

class _DevicePickerSheet extends StatefulWidget {
  const _DevicePickerSheet();

  @override
  State<_DevicePickerSheet> createState() => _DevicePickerSheetState();
}

class _DevicePickerSheetState extends State<_DevicePickerSheet> {
  final _valid = <String, ScanResult>{};
  final _other = <String, String>{};

  bool _scanning = true;
  StreamSubscription? _scanSub;

  bool _isValid(ScanResult r) {
    final a = r.advertisementData;
    return a.serviceUuids.any((g) => g.str128 == DocasaContract.serviceUuid) ||
        (a.advName.isNotEmpty
                ? a.advName
                : r.device.advName) ==
            DocasaContract.deviceName;
  }

  @override
  void initState() {
    super.initState();
    _scanSub = FlutterBluePlus.scanResults.listen((batch) {
      if (!mounted) return;
      for (final r in batch) {
        final name = r.advertisementData.advName.isNotEmpty
            ? r.advertisementData.advName
            : r.device.advName;
        if (_isValid(r)) {
          _valid[r.device.remoteId.str] = r;
        } else if (name.isNotEmpty) {
          _other[r.device.remoteId.str] =
              '$name [${r.advertisementData.serviceUuids.map((g) => g.str128).join(', ')}]';
        }
      }
      setState(() {});
    });
    FlutterBluePlus.isScanning.listen((s) {
      if (mounted) setState(() => _scanning = s);
    });
    FlutterBluePlus
        .startScan(timeout: const Duration(seconds: 15));
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    FlutterBluePlus
        .stopScan(); // fire-and-forget; sheet is closing
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final validList = _valid.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _scanning ? 'Scanning for the air purifier…' : 'Device selection',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            if (_scanning) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            if (validList.isEmpty && !_scanning)
              Text(
                _other.isEmpty
                    ? 'No Bluetooth devices with advertisements were seen. '
                        'Is the purifier powered?'
                    : 'No DOCASA advertisement found. Nearby devices for '
                        'diagnosis (firmware advertising is unverified — D-019):',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (validList.isEmpty)
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final e in _other.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(e.value,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                        ),
                    ],
                  ),
                ),
              ),
            for (final r in validList)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(r.advertisementData.advName.isNotEmpty
                    ? r.advertisementData.advName
                    : r.device.advName),
                // Signal strength as a simple bar meter, not a dBm figure
                // (D-033: user-friendly device rows).
                trailing: Icon(
                  switch (r.rssi) {
                    final s when s >= -60 => Icons.signal_cellular_alt,
                    final s when s >= -75 => Icons.signal_cellular_alt_2_bar,
                    _ => Icons.signal_cellular_alt_1_bar,
                  },
                  size: 22,
                ),
                leading: const Icon(Icons.air),
                onTap: () => Navigator.pop(context, r.device),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
