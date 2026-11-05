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
    this.stageSeconds = const [],
  });

  /// RPM·s — Σ commanded-RPM × dt (uint64 on device).
  final int fanSeconds;

  /// RPM·µg·s — Σ commanded-RPM × PM2.5 × dt (uint64 on device).
  final int pmWeightedFanSeconds;

  /// Whole hours powered — device lifecycle, never reset by `resetFilter`.
  final int powerOnHours;

  /// v1.1 (§4.4 `"st"`) — per-stage seconds since the last `resetFilter`
  /// (index 0 = stage 1 GOOD … index 4 = stage 5 HAZARD). Empty on
  /// pre-4.2.0 firmware (D-027 fallback rule) or when the key is absent.
  final List<int> stageSeconds;

  /// Dirty-air exposure of the desired basis: Σ `st[2..4]` seconds
  /// (POOR/BAD/HAZARD — D-027). 0 when the key is unavailable.
  int get dirtyAirSeconds {
    if (stageSeconds.length < 5) return 0;
    return stageSeconds[2] + stageSeconds[3] + stageSeconds[4];
  }

  @override
  String toString() =>
      'FilterCounters(fs:$fanSeconds pwfs:$pmWeightedFanSeconds on:$powerOnHours h st:$stageSeconds)';
}

/// Contract v1.1 §10.1 — one decoded offline envelope window (10 minutes).
class OfflineWindowSample {
  const OfflineWindowSample({
    required this.pmMin,
    required this.pmMean,
    required this.pmMax,
    required this.stageSeconds,
  });

  /// µg/m³, sensor-domain (≤999 — torn/power-cut writes read 65535 and are
  /// rejected by the codec, §10.1).
  final int pmMin;
  final int pmMean;
  final int pmMax;

  /// Seconds per contract stage inside the 10-min window (index 0 = GOOD …).
  final List<int> stageSeconds;

  @override
  String toString() =>
      'OfflineWindow(pm $pmMin/$pmMean/$pmMax st:$stageSeconds)';
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
