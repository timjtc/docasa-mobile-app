import 'dart:async';

import '../../protocol/codec.dart';
import '../../protocol/models.dart';
import '../docasa_connection.dart';
import 'fake_generator.dart';

/// Phase 3 device emulator: drives the entire app without hardware.
///
/// Every tick is **encoded to a Contract v1 JSON payload and decoded back
/// through [DocasaCodec]** — the same decode path the real BLE implementation
/// will use — so the codec is exercised end-to-end on every simulated second.
///
/// Phase 4 swaps in a `flutter_blue_plus` implementation of
/// [DocasaConnection]; nothing above this layer changes.
class FakeDocasaConnection implements DocasaConnection {
  FakeDocasaConnection({FakeDocasaGenerator? generator})
      : _gen = generator ?? FakeDocasaGenerator();

  final FakeDocasaGenerator _gen;

  final _statesCtrl =
      StreamController<DocasaConnectionState>.broadcast();
  final _telemetryCtrl =
      StreamController<DocasaTelemetry>.broadcast();

  Timer? _timer;
  DocasaConnectionState _state = DocasaConnectionState.disconnected;

  int _lastTimeSyncEpoch = 0;
  bool _timeSynced = false;

  /// Contract §6.1 — the app re-syncs time on every connect.
  int get lastTimeSyncEpoch => _lastTimeSyncEpoch;
  bool get timeSynced => _timeSynced;

  @override
  Stream<DocasaConnectionState> get states => _statesCtrl.stream;

  @override
  Stream<DocasaTelemetry> get telemetry => _telemetryCtrl.stream;

  @override
  Future<void> connect() async {
    if (_state != DocasaConnectionState.disconnected) return;
    _setState(DocasaConnectionState.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _setState(DocasaConnectionState.connected);
    await syncTime(); // Contract §6.1 handshake
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  Future<void> disconnect() async {
    _timer?.cancel();
    _timer = null;
    _setState(DocasaConnectionState.disconnected);
  }

  @override
  Future<DocasaDeviceInfo> readDeviceInfo() async => const DocasaDeviceInfo(
        manufacturer: 'DOCASA',
        model: 'DOCASA Air Purifier',
        firmwareRevision: '4.1.0',
        hardwareRevision: 'ESP32-WROOM-v3',
      );

  @override
  Future<FilterCounters> readFilterCounters() async =>
      DocasaCodec.decodeFilterCounters(
        DocasaCodec.encodeFilterCounters(_gen.counters),
      );

  @override
  Future<void> syncTime() async {
    _lastTimeSyncEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _timeSynced = true;
  }

  @override
  Future<void> resetFilter() async => _gen.resetFilter();

  void _onTick() {
    final t = _gen.step();
    try {
      final telemetry = DocasaTelemetry(
        at: DateTime.now(),
        air: DocasaCodec.decodeAirQuality(
            DocasaCodec.encodeAirQuality(t.air)),
        env: DocasaCodec.decodeEnvironment(
            DocasaCodec.encodeEnvironment(t.env)),
        sys: DocasaCodec.decodeSystemStatus(
            DocasaCodec.encodeSystemStatus(t.sys)),
      );
      _telemetryCtrl.add(telemetry);
    } on Exception catch (e) {
      _telemetryCtrl.addError(e); // e.g. ProtocolVersionException (X4)
    }
  }

  void _setState(DocasaConnectionState s) {
    _state = s;
    _statesCtrl.add(s);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statesCtrl.close();
    _telemetryCtrl.close();
  }
}
