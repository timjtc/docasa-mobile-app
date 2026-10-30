/// DOCASA protocol v1 codec — the executable form of `docs/BLE-Protocol-Contract.md`.
///
/// This is the ONLY file that knows the payload grammar. Decoding is strict on
/// structure and version, permissive on domain (unknown keys ignored — X5;
/// invalid domains decoded raw and clamped/flagged by the UI — X6).
/// Encoding exists for the device emulator and golden round-trip tests.
library;

import 'dart:convert';

import 'contract.dart';
import 'models.dart';

/// Contract §7: wrong/missing `"v"` → surfaced to the UI as unsupported protocol.
class ProtocolVersionException implements Exception {
  ProtocolVersionException(this.received);

  final int? received;

  @override
  String toString() =>
      'Unsupported DOCASA protocol version: $received '
      '(expected ${DocasaContract.payloadVersion})';
}

/// Structurally invalid payload (not JSON / not an object / missing key).
class MalformedPayloadException implements Exception {
  MalformedPayloadException(this.reason, [this.payload]);

  final String reason;
  final String? payload;

  @override
  String toString() => 'Malformed DOCASA payload: $reason';
}

/// uint64 values may exceed Dart's signed 64-bit int when a device misbehaves —
/// clamp instead of throwing (realistic values are ~1e11, far below this).
const int _maxInt = 9223372036854775807;

Map<String, dynamic> _parse(String payload) {
  final dynamic root;
  try {
    root = jsonDecode(payload);
  } catch (_) {
    throw MalformedPayloadException('not valid JSON', payload); // fixture X1
  }
  if (root is! Map<String, dynamic>) {
    throw MalformedPayloadException('root is not a JSON object', payload);
  }
  final v = root['v'];
  if (v is! num) {
    throw MalformedPayloadException('missing "v"', payload);
  }
  if (v.round() != DocasaContract.payloadVersion) {
    throw ProtocolVersionException(v.round()); // fixture X4
  }
  return root;
}

num _req(Map<String, dynamic> m, String key, String payload) {
  final x = m[key];
  if (x is! num) {
    throw MalformedPayloadException('missing or non-numeric "$key"', payload);
  }
  return x;
}

int _reqInt(Map<String, dynamic> m, String key, String payload) =>
    _req(m, key, payload).round();

double _reqDouble(Map<String, dynamic> m, String key, String payload) =>
    _req(m, key, payload).toDouble();

bool _reqBit(Map<String, dynamic> m, String key, String payload) {
  final x = m[key];
  if (x is bool) return x;
  if (x is num) return x != 0;
  throw MalformedPayloadException('missing or non-numeric "$key"', payload);
}

int _reqU64(Map<String, dynamic> m, String key, String payload) {
  final raw = _req(m, key, payload).round();
  if (raw <= 0) return 0;
  return raw > _maxInt ? _maxInt : raw;
}

abstract final class DocasaCodec {
  // ---------------------------------------------------------------- decode

  static AirQualitySample decodeAirQuality(String payload) {
    final m = _parse(payload);
    return AirQualitySample(
      pm1: _reqInt(m, 'pm1', payload),
      pm25: _reqInt(m, 'pm25', payload),
      pm10: _reqInt(m, 'pm10', payload),
      stage: _reqInt(m, 'st', payload),
    );
  }

  static EnvironmentSample decodeEnvironment(String payload) {
    final m = _parse(payload);
    return EnvironmentSample(
      temperature: _reqDouble(m, 't', payload),
      humidity: _reqDouble(m, 'h', payload),
      vocKOhms: _reqDouble(m, 'voc', payload),
    );
  }

  static SystemStatusSample decodeSystemStatus(String payload) {
    final m = _parse(payload);
    return SystemStatusSample(
      fanRpm: _reqInt(m, 'fan', payload),
      batteryPct: _reqInt(m, 'bat', payload),
      charging: _reqBit(m, 'chg', payload),
      batteryFull: _reqBit(m, 'full', payload),
      batteryVoltage: _reqDouble(m, 'vb', payload),
    );
  }

  static FilterCounters decodeFilterCounters(String payload) {
    final m = _parse(payload);
    return FilterCounters(
      fanSeconds: _reqU64(m, 'fs', payload),
      pmWeightedFanSeconds: _reqU64(m, 'pwfs', payload),
      powerOnHours: _reqU64(m, 'on', payload),
    );
  }

  // ---------------------------------------------------------------- encode
  // Device-side emulation (FakeDocasaDevice) + golden tests. Key order matches
  // the Contract §4 canonical fixtures.

  static String encodeAirQuality(AirQualitySample s) => jsonEncode(<String, dynamic>{
        'v': DocasaContract.payloadVersion,
        'pm1': s.pm1,
        'pm25': s.pm25,
        'pm10': s.pm10,
        'st': s.stage,
      });

  static String encodeEnvironment(EnvironmentSample s) =>
      jsonEncode(<String, dynamic>{
        'v': DocasaContract.payloadVersion,
        't': _roundTo(s.temperature, 1),
        'h': _roundTo(s.humidity, 1),
        'voc': _roundTo(s.vocKOhms, 1),
      });

  static String encodeSystemStatus(SystemStatusSample s) =>
      jsonEncode(<String, dynamic>{
        'v': DocasaContract.payloadVersion,
        'fan': s.fanRpm,
        'bat': s.batteryPct,
        'chg': s.charging ? 1 : 0,
        'full': s.batteryFull ? 1 : 0,
        'vb': _roundTo(s.batteryVoltage, 2),
      });

  static String encodeFilterCounters(FilterCounters c) =>
      jsonEncode(<String, dynamic>{
        'v': DocasaContract.payloadVersion,
        'fs': c.fanSeconds,
        'pwfs': c.pmWeightedFanSeconds,
        'on': c.powerOnHours,
      });

  // Commands (Contract §5). Time sync is re-sent on every connect.

  static String encodeResetFilterCommand() => jsonEncode(<String, dynamic>{
        'cmd': 'resetFilter',
      });

  static String encodeTimeSyncCommand({required int epochSeconds}) =>
      jsonEncode(<String, dynamic>{
        'cmd': 'time',
        'epoch': epochSeconds,
      });

  /// Mirrors the firmware's fixed-decimal rounding so emulated payloads are
  /// byte-identical to golden fixtures.
  static double _roundTo(double x, int decimals) {
    var f = 1.0;
    for (var i = 0; i < decimals; i++) {
      f *= 10;
    }
    return (x * f).round() / f;
  }
}
