import '../protocol/models.dart';

/// Transport-agnostic connection to a DOCASA air purifier.
///
/// Phase 3 implementation: `ble/fake/fake_docasa_connection.dart` (device
/// emulator — drives the whole app without hardware). Phase 4 swaps in a
/// `flutter_blue_plus` implementation behind this same interface.
abstract interface class DocasaConnection {
  /// Connection lifecycle. Single central at a time (Plan §7.9).
  Stream<DocasaConnectionState> get states;

  /// Merged 1 Hz telemetry frames. Timestamps are phone-side (Contract §6.7).
  ///
  /// The stream yields errors (not crashes) for undecodable payloads —
  /// e.g. [ProtocolVersionException] on a future `v:2` device (X4).
  Stream<DocasaTelemetry> get telemetry;

  /// Device Information Service snapshot (Contract §3).
  Future<DocasaDeviceInfo> readDeviceInfo();

  /// Filter Counters snapshot (Contract §4.4). App polls — no notify.
  Future<FilterCounters> readFilterCounters();

  /// Contract §5/§6.1 — re-sent automatically on every connect by the
  /// implementation; also callable directly.
  Future<void> syncTime();

  /// Contract §5. UI-gated until Phase 5 (security ruling D-010).
  Future<void> resetFilter();

  Future<void> connect();

  Future<void> disconnect();

  void dispose();
}
