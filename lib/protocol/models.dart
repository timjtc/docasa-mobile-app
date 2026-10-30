/// Typed models for the DOCASA protocol v1 payloads (Contract §4).
///
/// Models carry decoded values as sent by the device. Domain validation
/// (e.g. stage 1–5, non-negative PM) is deliberately NOT enforced here —
/// per Contract §8/X6 the codec decodes permissively and the UI clamps/flags.
library;

/// Contract §4.1 — Air Quality characteristic.
class AirQualitySample {
  const AirQualitySample({
    required this.pm1,
    required this.pm25,
    required this.pm10,
    required this.stage,
  });

  /// µg/m³. Device variable `pm10Value` (v3 name — holds PM1.0, Plan §1.2).
  final int pm1;

  /// µg/m³. Device variable `pm25Value`.
  final int pm25;

  /// µg/m³. Device variable `pm100Value`.
  final int pm10;

  /// 1–5 as sent by the device (`overallStage`).
  final int stage;

  @override
  String toString() => 'AirQuality(pm1:$pm1 pm25:$pm25 pm10:$pm10 st:$stage)';
}

/// Contract §4.2 — Environment characteristic.
class EnvironmentSample {
  const EnvironmentSample({
    required this.temperature,
    required this.humidity,
    required this.vocKOhms,
  });

  /// °C.
  final double temperature;

  /// % RH.
  final double humidity;

  /// kΩ — raw BME680 gas-resistance proxy, qualitative only (Plan §4.5).
  final double vocKOhms;

  @override
  String toString() => 'Environment(t:$temperature h:$humidity voc:$vocKOhms)';
}

/// Contract §4.3 — System Status characteristic.
class SystemStatusSample {
  const SystemStatusSample({
    required this.fanRpm,
    required this.batteryPct,
    required this.charging,
    required this.batteryFull,
    required this.batteryVoltage,
  });

  /// RPM — commanded target (v3 semantics; measured RPM would be a future
  /// additive `rpm` key, Contract §4.3).
  final int fanRpm;

  /// 0–100.
  final int batteryPct;

  final bool charging;

  /// "Truly full" detection on device.
  final bool batteryFull;

  /// V — EMA-smoothed pack voltage.
  final double batteryVoltage;

  @override
  String toString() =>
      'SystemStatus(fan:$fanRpm bat:$batteryPct chg:$charging full:$batteryFull vb:$batteryVoltage)';
}

/// Contract §4.4 — Filter Counters (raw device-side integrals).
class FilterCounters {
  const FilterCounters({
    required this.fanSeconds,
    required this.pmWeightedFanSeconds,
    required this.powerOnHours,
  });

  /// RPM·s — Σ commanded-RPM × dt (uint64 on device).
  final int fanSeconds;

  /// RPM·µg·s — Σ commanded-RPM × PM2.5 × dt (uint64 on device).
  final int pmWeightedFanSeconds;

  /// Whole hours powered — device lifecycle, never reset by `resetFilter`.
  final int powerOnHours;

  @override
  String toString() =>
      'FilterCounters(fs:$fanSeconds pwfs:$pmWeightedFanSeconds on:$powerOnHours h)';
}

/// Device Information Service values (Contract §3).
class DocasaDeviceInfo {
  const DocasaDeviceInfo({
    required this.manufacturer,
    required this.model,
    required this.firmwareRevision,
    required this.hardwareRevision,
  });

  final String manufacturer;
  final String model;
  final String firmwareRevision;
  final String hardwareRevision;
}

/// One merged telemetry frame at a given (phone-side) instant.
///
/// Fields are null until the corresponding characteristic has delivered its
/// first value (partial during the handshake snapshot, Contract §6.1).
/// The timestamp is **app-side** — the phone is the time authority
/// (Contract §6.7; device epoch is untrusted across reboots).
class DocasaTelemetry {
  const DocasaTelemetry({
    required this.at,
    this.air,
    this.env,
    this.sys,
  });

  final DateTime at;
  final AirQualitySample? air;
  final EnvironmentSample? env;
  final SystemStatusSample? sys;

  DocasaTelemetry copyWith({
    DateTime? at,
    AirQualitySample? air,
    EnvironmentSample? env,
    SystemStatusSample? sys,
  }) =>
      DocasaTelemetry(
        at: at ?? this.at,
        air: air ?? this.air,
        env: env ?? this.env,
        sys: sys ?? this.sys,
      );

  /// True once every domain has delivered at least once.
  bool get complete => air != null && env != null && sys != null;
}

/// Connection lifecycle states surfaced by a [DocasaConnection].
enum DocasaConnectionState { disconnected, connecting, connected }
