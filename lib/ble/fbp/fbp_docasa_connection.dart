import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../protocol/codec.dart';
import '../../protocol/contract.dart';
import '../../protocol/models.dart';
import '../docasa_connection.dart';

/// Reconnect backoff (Plan §7.15): 0.5 s doubling, capped at 8 s. Pure + test.
Duration backoffDelay(int attempt) =>
    Duration(milliseconds: min(500 << (attempt - 1), 8000));

/// Real BLE transport (Phase 4).
///
/// D-017: built without hardware by user decision — code-complete and
/// analyzer-gated against flutter_blue_plus 2.x; runtime behavior (GATT
/// notify alignment, MTU, reconnect paths) is what G4 verifies after the
/// bench session. The codec/handshake paths are identical to the emulator's.
class FbpDocasaConnection implements DocasaConnection {
  final _statesCtrl = StreamController<DocasaConnectionState>.broadcast();
  final _telemetryCtrl = StreamController<DocasaTelemetry>.broadcast();

  String? _airJson, _envJson, _sysJson;

  BluetoothDevice? _device;
  StreamSubscription? _airSub, _envSub, _sysSub, _dropSub;
  bool _run = false;

  @override
  Stream<DocasaConnectionState> get states => _statesCtrl.stream;

  @override
  Stream<DocasaTelemetry> get telemetry => _telemetryCtrl.stream;

  void _emit(DocasaConnectionState s) => _statesCtrl.add(s);

  /// Runs until disconnect()/dispose(): connect → subscribe → on drop,
  /// reconnect with 0.5→8 s backoff. Backoff resets after each successful
  /// handshake.
  @override
  Future<void> connect() async {
    if (_run) return;
    _run = true;
    var attempt = 0;
    while (_run) {
      _emit(DocasaConnectionState.connecting);
      final linked = await _link();
      if (!_run) return;
      // Keep the link until it drops: _link() completes on disconnect.
      if (linked) attempt = 0;
      _airJson = _envJson = _sysJson = null;
      attempt = max(1, attempt + 1);
      await Future<void>.delayed(backoffDelay(attempt));
    }
  }

  /// One connect cycle: permissions → UUID scan → connect → MTU → handshake
  /// subscriptions. Returns when the link drops (whatever the next step is).
  Future<bool> _link() async {
    if (!await _ensurePermissions()) {
      _run = false;
      _emit(DocasaConnectionState.disconnected);
      return false;
    }

    BluetoothDevice dev;
    try {
      dev = await _scanOnce();
      _device = dev;
      // FBLP 2.x is dual-licensed (License enum on connect) — nonprofit tier
      // for personal use (D-018). mtu: 247 is negotiated in one step (§7.20).
      await dev.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 15),
        mtu: 247,
      );
      await _handshake();
      _emit(DocasaConnectionState.connected);
    } catch (_) {
      // Scan timeout, device vanished mid-handshake, missing chars, StateError.
      _device = null;
      return false;
    }

    // FBLP's connectionState stream echoes the current state first, so a drop
    // that already happened completes immediately (no race hang).
    final dropped = Completer<void>();
    _dropSub = dev.connectionState.listen((cs) {
      if (cs == BluetoothConnectionState.disconnected && !dropped.isCompleted) {
        dropped.complete();
      }
    });
    await dropped.future;
    return true;
  }

  Future<BluetoothDevice> _scanOnce() async {
    await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        withServices: [Guid(DocasaContract.serviceUuid)]);
    final List<ScanResult> found;
    try {
      found = await FlutterBluePlus.scanResults
          .firstWhere((list) => list.isNotEmpty)
          .timeout(const Duration(seconds: 12), onTimeout: () => const []);
    } finally {
      await FlutterBluePlus.stopScan();
    }
    if (found.isEmpty) {
      throw const SocketException('no DOCASA device found');
    }
    return found.first.device;
  }

  Future<void> _handshake() async {
    final dev = _device!;
    final services = await dev.discoverServices();
    BluetoothCharacteristic? byUuid(String uuid) {
      for (final s in services) {
        for (final c in s.characteristics) {
          if (c.uuid.str128 == uuid) return c;
        }
      }
      return null;
    }

    // Telemetry CCCDs (Contract §2): merged into complete 1 Hz frames.
    final air = byUuid(DocasaContract.airQualityUuid);
    final env = byUuid(DocasaContract.environmentUuid);
    final sys = byUuid(DocasaContract.systemStatusUuid);
    if (air == null || env == null || sys == null) {
      throw StateError('telemetry characteristics missing');
    }
    _teardownSubs();
    await air.setNotifyValue(true);
    _airSub = air.onValueReceived.listen((b) => _onAir(utf8.decode(b)));
    await env.setNotifyValue(true);
    _envSub = env.onValueReceived.listen((b) => _onEnv(utf8.decode(b)));
    await sys.setNotifyValue(true);
    _sysSub = sys.onValueReceived.listen((b) => _onSys(utf8.decode(b)));
    await syncTime(); // Contract §6.1 — every connect
  }

  void _teardownSubs() {
    _airSub?.cancel();
    _envSub?.cancel();
    _sysSub?.cancel();
    _airSub = _envSub = _sysSub = null;
  }

  // Frame merge: emit only when all three characteristic buffers refreshed
  // since the last emit — captures the device's per-second broadcast.
  void _onAir(String json) {
    _airJson = json;
    _maybeEmit();
  }

  void _onEnv(String json) {
    _envJson = json;
    _maybeEmit();
  }

  void _onSys(String json) {
    _sysJson = json;
    _maybeEmit();
  }

  void _maybeEmit() {
    if (_airJson == null || _envJson == null || _sysJson == null) return;
    final a = _airJson!, e = _envJson!, s = _sysJson!;
    _airJson = _envJson = _sysJson = null;
    try {
      _telemetryCtrl.add(DocasaTelemetry(
        at: DateTime.now(), // phone-side timebase (Contract §6.7)
        air: DocasaCodec.decodeAirQuality(a),
        env: DocasaCodec.decodeEnvironment(e),
        sys: DocasaCodec.decodeSystemStatus(s),
      ));
    } on Exception catch (e) {
      _telemetryCtrl.addError(e); // per Contract X-tests (version drift etc.)
    }
  }

  @override
  Future<DocasaDeviceInfo> readDeviceInfo() async {
    final services = await _device!.discoverServices();
    BluetoothService? find(Guid g) => services.firstWhere((s) => s.uuid == g);
    final svc = find(Guid(DocasaContract.deviceInformationServiceUuid));
    Future<String> read(String uuid) async {
      final c = svc?.characteristics.firstWhere(
        (c) => c.uuid.str128 == uuid,
      );
      return utf8.decode(await c?.read() ?? const []);
    }

    return DocasaDeviceInfo(
      manufacturer: await read(DocasaContract.manufacturerNameUuid),
      model: await read(DocasaContract.modelNumberUuid),
      firmwareRevision: await read(DocasaContract.firmwareRevisionUuid),
      hardwareRevision: await read(DocasaContract.hardwareRevisionUuid),
    );
  }

  @override
  Future<FilterCounters> readFilterCounters() async {
    final services = await _device!.discoverServices();
    for (final s in services) {
      for (final c in s.characteristics) {
        if (c.uuid.str128 == DocasaContract.filterCountersUuid) {
          return DocasaCodec.decodeFilterCounters(utf8.decode(await c.read()));
        }
      }
    }
    throw StateError('filter counters characteristic missing');
  }

  @override
  Future<void> syncTime() async => _writeCommand(
      DocasaCodec.encodeTimeSyncCommand(
          epochSeconds: DateTime.now().millisecondsSinceEpoch ~/ 1000));

  @override
  Future<void> resetFilter() async =>
      _writeCommand(DocasaCodec.encodeResetFilterCommand());

  Future<void> _writeCommand(String json) async {
    final services = await _device!.discoverServices();
    for (final s in services) {
      for (final c in s.characteristics) {
        if (c.uuid.str128 == DocasaContract.commandUuid) {
          await c.write(utf8.encode(json));
          return;
        }
      }
    }
    throw StateError('command characteristic missing');
  }

  /// Android 12+ scan/connect runtime permissions; `locationWhenInUse` covers
  /// API ≤ 30 discovery (manifest hides it on 31+). Denial stops reconnecting
  /// gracefully — the device page stays on "No device connected".
  Future<bool> _ensurePermissions() async {
    if (!Platform.isAndroid) return true;
    final granted = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return granted.values.every(
        (s) => s.isGranted || s.isLimited || s.isProvisional);
  }

  @override
  Future<void> disconnect() async {
    _run = false;
    final d = _device;
    _device = null;
    _teardownSubs();
    _dropSub?.cancel();
    _dropSub = null;
    _airJson = _envJson = _sysJson = null;
    _emit(DocasaConnectionState.disconnected);
    try {
      await d?.disconnect(); // severs the real link; completes the await in _link
    } catch (_) {}
  }

  @override
  void dispose() {
    unawaited(disconnect());
    _statesCtrl.close();
    _telemetryCtrl.close();
  }
}
