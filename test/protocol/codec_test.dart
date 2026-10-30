import 'package:flutter_test/flutter_test.dart';
import 'package:docasa_app/core/stage.dart';
import 'package:docasa_app/protocol/codec.dart';
import 'package:docasa_app/protocol/models.dart';

/// Golden fixtures — normative, from docs/BLE-Protocol-Contract.md §8.
const f1 = '{"v":1,"pm1":14,"pm25":8,"pm10":21,"st":2}';
const f2 = '{"v":1,"t":24.6,"h":47.2,"voc":38.4}';
const f3 = '{"v":1,"fan":3000,"bat":84,"chg":0,"full":0,"vb":15.31}';
const f4 = '{"v":1,"fan":0,"bat":7,"chg":1,"full":0,"vb":13.62}';
const f5 = '{"v":1,"fs":10800000,"pwfs":74250000,"on":3210}';
const f6 = '{"cmd":"resetFilter"}';
const f7 = '{"cmd":"time","epoch":1769472000}';

void main() {
  group('decode goldens (F1–F5)', () {
    test('F1 air quality', () {
      final s = DocasaCodec.decodeAirQuality(f1);
      expect(s.pm1, 14);
      expect(s.pm25, 8);
      expect(s.pm10, 21);
      expect(s.stage, 2);
    });

    test('F2 environment', () {
      final s = DocasaCodec.decodeEnvironment(f2);
      expect(s.temperature, 24.6);
      expect(s.humidity, 47.2);
      expect(s.vocKOhms, 38.4);
    });

    test('F3 system status', () {
      final s = DocasaCodec.decodeSystemStatus(f3);
      expect(s.fanRpm, 3000);
      expect(s.batteryPct, 84);
      expect(s.charging, isFalse);
      expect(s.batteryFull, isFalse);
      expect(s.batteryVoltage, 15.31);
    });

    test('F4 system status — fan off, charging', () {
      final s = DocasaCodec.decodeSystemStatus(f4);
      expect(s.fanRpm, 0);
      expect(s.batteryPct, 7);
      expect(s.charging, isTrue);
      expect(s.batteryVoltage, 13.62);
    });

    test('F5 filter counters', () {
      final c = DocasaCodec.decodeFilterCounters(f5);
      expect(c.fanSeconds, 10800000);
      expect(c.pmWeightedFanSeconds, 74250000);
      expect(c.powerOnHours, 3210);
    });
  });

  group('encode goldens (byte-identical, canonical key order)', () {
    test('air quality round-trip', () {
      expect(
        DocasaCodec.encodeAirQuality(
            const AirQualitySample(pm1: 14, pm25: 8, pm10: 21, stage: 2)),
        f1,
      );
    });

    test('environment round-trip', () {
      expect(
        DocasaCodec.encodeEnvironment(const EnvironmentSample(
            temperature: 24.6, humidity: 47.2, vocKOhms: 38.4)),
        f2,
      );
    });

    test('system status round-trip', () {
      expect(
        DocasaCodec.encodeSystemStatus(const SystemStatusSample(
            fanRpm: 3000,
            batteryPct: 84,
            charging: false,
            batteryFull: false,
            batteryVoltage: 15.31)),
        f3,
      );
    });

    test('filter counters round-trip', () {
      expect(
        DocasaCodec.encodeFilterCounters(const FilterCounters(
            fanSeconds: 10800000,
            pmWeightedFanSeconds: 74250000,
            powerOnHours: 3210)),
        f5,
      );
    });

    test('commands F6/F7', () {
      expect(DocasaCodec.encodeResetFilterCommand(), f6);
      expect(DocasaCodec.encodeTimeSyncCommand(epochSeconds: 1769472000), f7);
    });
  });

  group('invalid inputs (X1–X6) — tolerated per Contract §5/§8', () {
    test('X1: not JSON → MalformedPayloadException', () {
      expect(() => DocasaCodec.decodeAirQuality('not json'),
          throwsA(isA<MalformedPayloadException>()));
    });

    test('X4: future protocol version → ProtocolVersionException', () {
      expect(
        () => DocasaCodec.decodeAirQuality(
            '{"v":2,"pm1":5,"pm25":8,"pm10":21,"st":2}'),
        throwsA(isA<ProtocolVersionException>()),
      );
    });

    test('missing "v" → MalformedPayloadException', () {
      expect(
        () => DocasaCodec.decodeAirQuality('{"pm1":5,"pm25":8,"pm10":21,"st":2}'),
        throwsA(isA<MalformedPayloadException>()),
      );
    });

    test('missing required key → MalformedPayloadException', () {
      expect(() => DocasaCodec.decodeAirQuality('{"v":1,"pm25":8,"st":2}'),
          throwsA(isA<MalformedPayloadException>()));
    });

    test('X5: unknown keys ignored', () {
      final s = DocasaCodec
          .decodeAirQuality('{"v":1,"pm1":14,"pm25":8,"pm10":21,"st":2,"unknown":9}');
      expect(s.pm1, 14);
      expect(s.stage, 2);
    });

    test('X6: invalid domain decodes raw — UI clamps/flags', () {
      final s = DocasaCodec
          .decodeAirQuality('{"v":1,"pm1":-1,"pm25":8,"pm10":21,"st":0}');
      expect(s.pm1, -1);
      expect(s.stage, 0);
      expect(DomainClamps.pm(-1), 0);
      expect(AirStage.fromIndex(0), isNull);
      expect(AirStage.clamped(0), AirStage.good);
      expect(AirStage.clamped(9), AirStage.hazard);
    });

    test('uint64 above Dart int64 range clamps (7.20 robustness)', () {
      final c = DocasaCodec.decodeFilterCounters(
          '{"v":1,"fs":18446744073709551615,"pwfs":18446744073709551615,"on":4294967295}');
      expect(c.fanSeconds, 9223372036854775807);
      expect(c.pmWeightedFanSeconds, 9223372036854775807);
      expect(c.powerOnHours, 4294967295);
    });

    test('chg/full tolerate bool encoding', () {
      final s = DocasaCodec
          .decodeSystemStatus('{"v":1,"fan":1000,"bat":50,"chg":true,"full":false,"vb":14.2}');
      expect(s.charging, isTrue);
      expect(s.batteryFull, isFalse);
    });
  });
}
