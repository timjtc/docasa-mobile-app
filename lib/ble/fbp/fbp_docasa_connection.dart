import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
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
  BluetoothDevice? _picked;
  StreamSubscription? _airSub, _envSub, _sysSub, _dropSub;
  bool _run = false;
  bool _logFirstFrameDone = false;

  @override
  Stream<DocasaConnectionState> get states => _statesCtrl.stream;

  @override
  Stream<DocasaTelemetry> get telemetry => _telemetryCtrl.stream;

  void _emit(DocasaConnectionState s) {
    debugPrint('FBP: state → $s');
    _statesCtrl.add(s);
  }

  /// Runs against the picker-chosen device until disconnect()/dispose():
  /// connect → subscribe → on drop, reconnect with 0.5→8 s backoff. Backoff
  /// resets after each successful handshake.
  Future<void> connectTo(BluetoothDevice device) async {
    _picked = device;
    if (_run) return;
    _run = true;
    var attempt = 0;
    while (_run) {
      _emit(DocasaConnectionState.connecting);
      final linked = await _link(device);
      if (!_run) return;
      if (linked) attempt = 0;
      _airJson = _envJson = _sysJson = null;
      attempt = max(1, attempt + 1);
      await Future<void>.delayed(backoffDelay(attempt));
    }
  }

  @override
  Future<void> connect() async {
    if (_run) return;
    final pick = _picked;
    if (pick == null) {
      debugPrint(
          'FBP: connect() with no picked device — user must choose first');
      return;
    }
    await connectTo(pick);
  }

  /// One connect cycle for the picked device: permissions → connect → MTU →
  /// handshake subscriptions. Returns when the link drops (whatever next).
  Future<bool> _link(BluetoothDevice dev) async {
    if (!await _ensurePermissions()) {
      _run = false;
      _emit(DocasaConnectionState.disconnected);
      return false;
    }

    try {
      debugPrint('FBP: connecting to ${dev.remoteId}');
      _device = dev;
      await dev.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 15),
        mtu: 247,
      );
      await _handshake();
      debugPrint('FBP: handshake done (CCCDs subscribed), link live');
      _emit(DocasaConnectionState.connected);
    } catch (e, st) {
      debugPrint('FBP: link failed: $e\n$st');
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
    debugPrint('FBP: link dropped, re-entering backoff loop');
    return true;
  }

  Future<void> _handshake() async {
    final dev = _device!;
    final services = await dev.discoverServices();

    // Handshake target verification (user requirement, Contract §3): the
    // connected device must present DOCASA device info — not some other
    // peripheral we accidentally selected in the picker.
    final info = await readDeviceInfo();
    debugPrint('FBP: handshake device info: '
        'mfg=${info.manufacturer} model=${info.model} fw=${info.firmwareRevision}');
    if (info.manufacturer != 'DOCASA' ||
        info.model != 'DOCASA Air Purifier' ||
        !info.firmwareRevision.startsWith('4.')) {
      throw StateError(
          'handshake verification failed — this is not a v4.x DOCASA purifier');
    }
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
      if (!_logFirstFrameDone) {
        _logFirstFrameDone = true;
        debugPrint('FBP: first complete frame decoded');
      }
    } on Exception catch (e) {
      debugPrint('FBP: frame decode error: $e');
      _telemetryCtrl.addError(e); // per Contract X-tests (version drift etc.)
    }
  }

  @override
  Future<DocasaDeviceInfo> readDeviceInfo() async {
    final services = await _device!.discoverServices();
    BluetoothService? find(Guid g) => services.firstWhere((s) => s.uuid == g);
    final svc = find(Guid(DocasaContract.deviceInformationServiceUuid));
    Future<String> read(String uuid) async {
      // Guid equality normalizes short-form IDs ('2A29') to the full
      // 128-bit runtime form; `str128 == uuid` never matched (D-025).
      final c = svc?.characteristics.firstWhere((c) => c.uuid == Guid(uuid));
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

  // Android 12+ scan/connect runtime permissions. shortcut: legacy (API ≤ 30)
  // discovery would also want fine location, but this manifest never requests
  // it (maxSdkVersion=30, scan is neverForLocation) — so a permanent `denied`
  // for location is safe to ignore. Upgrade: sdkInt-gated location request if
  // a pre-31 phone ever joins testing.
  Future<bool> _ensurePermissions() async {
    if (!Platform.isAndroid) return true;
    final granted = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    final ok = granted.values
        .every((s) => s.isGranted || s.isLimited || s.isProvisional);
    debugPrint('FBP: permissions '
        'scan=${granted[Permission.bluetoothScan]} '
        'connect=${granted[Permission.bluetoothConnect]}');
    return ok;
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
