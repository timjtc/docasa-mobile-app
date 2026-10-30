import 'dart:math' as math;

import '../../protocol/models.dart';

/// One simulated device-second.
class FakeTick {
  const FakeTick({required this.air, required this.env, required this.sys});

  final AirQualitySample air;
  final EnvironmentSample env;
  final SystemStatusSample sys;
}

// ---------------------------------------------------------------------------
// v3 firmware semantics mirrored exactly (docasa-air-purifier-v3.ino) so the
// emulated device behaves like the real one: PM thresholds from
// `calculateCompositeAQI()`, VOC bump (`gasResistance < 30 && > 0`), and the
// stage→RPM map from `updateFan()` (0/1000/2000/3000/4000).
// ---------------------------------------------------------------------------

int pm25StageOf(int pm25) {
  if (pm25 <= 12) return 1;
  if (pm25 <= 35) return 2;
  if (pm25 <= 55) return 3;
  if (pm25 <= 150) return 4;
  return 5;
}

int pm100StageOf(int pm100) {
  if (pm100 <= 54) return 1;
  if (pm100 <= 154) return 2;
  if (pm100 <= 254) return 3;
  if (pm100 <= 424) return 4;
  return 5;
}

int overallStageOf(int pm25, int pm10, double vocKOhms) {
  var s = math.max(pm25StageOf(pm25), pm100StageOf(pm10));
  if (vocKOhms < 30 && vocKOhms > 0 && s < 5) s++;
  return s;
}

int fanRpmOf(int stage) => switch (stage) {
      1 => 0,
      2 => 1000,
      3 => 2000,
      4 => 3000,
      5 => 4000,
      _ => 0,
    };

/// Deterministic device-state simulator. [step] advances exactly one device
/// second so tests can simulate hours instantly.
///
/// Counters accumulate with the same 1 Hz arithmetic as the v4.1 firmware
/// (`docasaIoTick`): fs += rpm, pwfs += rpm × PM2.5, onSec += 1.
class FakeDocasaGenerator {
  FakeDocasaGenerator({
    int seed = 42,
    FilterCounters? initialCounters,
  })  : _rng = math.Random(seed),
        _fanSeconds = initialCounters?.fanSeconds ?? 0,
        _pwfs = initialCounters?.pmWeightedFanSeconds ?? 0,
        _onSeconds =
            (initialCounters?.powerOnHours ?? 0) * 3600;

  final math.Random _rng;

  // air
  double _pm25Base = 8;
  int _eventLeft = 0;
  int _eventDuration = 1;
  double _eventMag = 0;

  // environment
  double _tempDrift = 0;
  double _humDrift = 0;
  double _vocBase = 45;
  int _vocDipLeft = 0;

  // battery
  double _battery = 84;
  bool _charging = false;
  int _chargingLeft = 0;

  // counters (firmware-mirror)
  int _fanSeconds;
  int _pwfs;
  int _onSeconds;

  /// Simulated seconds elapsed since generator start.
  int elapsed = 0;

  FilterCounters get counters => FilterCounters(
        fanSeconds: _fanSeconds,
        pmWeightedFanSeconds: _pwfs,
        powerOnHours: _onSeconds ~/ 3600,
      );

  void resetFilter() {
    _fanSeconds = 0;
    _pwfs = 0;
    // powerOnHours is device lifecycle — NOT reset (Contract §5).
  }

  FakeTick step() {
    elapsed++;

    // --- PM random walk with occasional dust events ---
    if (_eventLeft > 0) {
      _eventLeft--;
    } else if (_rng.nextDouble() < 0.002) {
      _eventDuration = 60 + _rng.nextInt(140);
      _eventLeft = _eventDuration;
      _eventMag = 30 + _rng.nextDouble() * 90;
    }
    _pm25Base = (_pm25Base + (_rng.nextDouble() - 0.5) * 1.2).clamp(2.0, 40.0);
    final eventExtra =
        _eventLeft > 0 ? _eventMag * _eventLeft / _eventDuration : 0.0;
    final pm25 =
        (_pm25Base + eventExtra + _rng.nextDouble() * 3).round().clamp(0, 999);
    final pm1 = (pm25 * 0.65 + _rng.nextDouble() * 2).round().clamp(0, 999);
    final pm10 = (pm25 * 1.45 + _rng.nextDouble() * 4).round().clamp(0, 999);

    // --- Environment slow walks + occasional VOC dips (triggers the bump) ---
    _tempDrift = (_tempDrift + (_rng.nextDouble() - 0.5) * 0.08).clamp(-2, 2);
    _humDrift = (_humDrift + (_rng.nextDouble() - 0.5) * 0.3).clamp(-10, 10);
    if (_vocDipLeft > 0) {
      _vocDipLeft--;
    } else if (_rng.nextDouble() < 0.0008) {
      _vocDipLeft = 30 + _rng.nextInt(30);
    }
    _vocBase = (_vocBase + (_rng.nextDouble() - 0.5) * 2).clamp(20.0, 90.0);
    final voc =
        _vocDipLeft > 0 ? 18 + _rng.nextDouble() * 8 : _vocBase + _rng.nextDouble() * 4;
    final temp = 24.5 + _tempDrift;
    final hum = 47 + _humDrift;

    // --- v3 stage + fan semantics ---
    final stage = overallStageOf(pm25, pm10, voc);
    final fanRpm = fanRpmOf(stage);

    // --- Battery: slow drain, occasional charge cycles ---
    if (_charging) {
      _chargingLeft--;
      _battery = (_battery + 0.02).clamp(0, 100);
      if (_chargingLeft <= 0 || _battery >= 100) _charging = false;
    } else if (_rng.nextDouble() < 1 / 1800) {
      _charging = true;
      _chargingLeft = 240;
    }
    if (!_charging) _battery = (_battery - 0.004).clamp(0, 100);
    final full = _charging && _battery >= 99.5;
    final vb = 13.0 + _battery / 100 * 3.41;

    // --- Firmware-mirror 1 Hz accumulation ---
    _fanSeconds += fanRpm;
    _pwfs += fanRpm * pm25;
    _onSeconds++;

    return FakeTick(
      air: AirQualitySample(pm1: pm1, pm25: pm25, pm10: pm10, stage: stage),
      env: EnvironmentSample(
        temperature: double.parse(temp.toStringAsFixed(1)),
        humidity: double.parse(hum.toStringAsFixed(1)),
        vocKOhms: double.parse(voc.toStringAsFixed(1)),
      ),
      sys: SystemStatusSample(
        fanRpm: fanRpm,
        batteryPct: _battery.round().clamp(0, 100),
        charging: _charging,
        batteryFull: full,
        batteryVoltage: double.parse(vb.toStringAsFixed(2)),
      ),
    );
  }
}
