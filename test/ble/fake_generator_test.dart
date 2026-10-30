import 'package:flutter_test/flutter_test.dart';
import 'package:docasa_app/ble/fake/fake_generator.dart';
import 'package:docasa_app/protocol/models.dart';

void main() {
  group('v3 firmware semantics mirror (stage/PM thresholds + fan map)', () {
    test('PM2.5 stage thresholds (calculateCompositeAQI)', () {
      expect(pm25StageOf(12), 1);
      expect(pm25StageOf(13), 2);
      expect(pm25StageOf(35), 2);
      expect(pm25StageOf(36), 3);
      expect(pm25StageOf(55), 3);
      expect(pm25StageOf(56), 4);
      expect(pm25StageOf(150), 4);
      expect(pm25StageOf(151), 5);
    });

    test('PM10 stage thresholds', () {
      expect(pm100StageOf(54), 1);
      expect(pm100StageOf(154), 2);
      expect(pm100StageOf(254), 3);
      expect(pm100StageOf(424), 4);
      expect(pm100StageOf(425), 5);
    });

    test('overall = max(PM stages), +1 VOC bump below 30 kΩ (capped at 5)', () {
      expect(overallStageOf(13, 20, 45), 2); // PM2.5 binds, clean VOC
      expect(overallStageOf(8, 20, 45), 1); // all clean
      expect(overallStageOf(8, 20, 25), 2); // VOC bump
      expect(overallStageOf(8, 20, 0), 1); // VOC=0 guard (sensor warming up)
      expect(overallStageOf(151, 30, 10), 5); // already 5 — no bump past 5
    });

    test('fan RPM map (updateFan)', () {
      expect(fanRpmOf(1), 0);
      expect(fanRpmOf(2), 1000);
      expect(fanRpmOf(3), 2000);
      expect(fanRpmOf(4), 3000);
      expect(fanRpmOf(5), 4000);
    });
  });

  group('generator behavior', () {
    test('domains stay valid over a long simulated run', () {
      final gen = FakeDocasaGenerator(seed: 42);
      for (var i = 0; i < 5000; i++) {
        final t = gen.step();
        expect(t.air.pm1, inInclusiveRange(0, 999));
        expect(t.air.pm25, inInclusiveRange(0, 999));
        expect(t.air.pm10, inInclusiveRange(0, 999));
        expect(t.air.stage, inInclusiveRange(1, 5));
        expect(t.sys.batteryPct, inInclusiveRange(0, 100));
        expect(t.sys.fanRpm, inInclusiveRange(0, 4000));
      }
    });

    test('counter accumulation mirrors the firmware 1 Hz arithmetic exactly',
        () {
      final gen = FakeDocasaGenerator(
          seed: 7, initialCounters: const FilterCounters(fanSeconds: 1000, pmWeightedFanSeconds: 5000, powerOnHours: 1));
      var expectedFs = 1000;
      var expectedPwfs = 5000;
      for (var i = 0; i < 600; i++) {
        final before = gen.counters;
        final t = gen.step();
        expectedFs += t.sys.fanRpm;
        expectedPwfs += t.sys.fanRpm * t.air.pm25;
        final after = gen.counters;
        expect(after.fanSeconds - before.fanSeconds, t.sys.fanRpm);
        expect(after.pmWeightedFanSeconds - before.pmWeightedFanSeconds,
            t.sys.fanRpm * t.air.pm25);
      }
      expect(gen.counters.fanSeconds, expectedFs);
      expect(gen.counters.pmWeightedFanSeconds, expectedPwfs);
      expect(gen.counters.powerOnHours, 1 + 600 ~/ 3600); // still 1 h
    });

    test('fan-off seconds add nothing to fs/pwfs (stage 1)', () {
      final gen = FakeDocasaGenerator(seed: 3);
      // Find two consecutive stage-1 ticks (clean air is the resting state).
      var checked = 0;
      for (var i = 0; i < 2000 && checked < 5; i++) {
        final before = gen.counters.fanSeconds;
        final t = gen.step();
        if (t.sys.fanRpm == 0) {
          expect(gen.counters.fanSeconds, before);
          checked++;
        }
      }
      expect(checked, greaterThan(0));
    });

    test('resetFilter zeroes integrals, preserves powered hours (Contract §5)',
        () {
      final gen = FakeDocasaGenerator(
          seed: 5, initialCounters: const FilterCounters(fanSeconds: 90000, pmWeightedFanSeconds: 400000, powerOnHours: 25));
      for (var i = 0; i < 100; i++) {
        gen.step();
      }
      gen.resetFilter();
      expect(gen.counters.fanSeconds, 0);
      expect(gen.counters.pmWeightedFanSeconds, 0);
      expect(gen.counters.powerOnHours, greaterThanOrEqualTo(25));
    });

    test('variety: simulated hour produces stage transitions and events', () {
      final gen = FakeDocasaGenerator(seed: 11);
      final stages = <int>{};
      var chargingSeen = false;
      for (var i = 0; i < 3600; i++) {
        final t = gen.step();
        stages.add(t.air.stage);
        if (t.sys.charging) chargingSeen = true;
      }
      expect(stages.length, greaterThanOrEqualTo(2),
          reason: 'dust events should lift the stage at least once');
      expect(chargingSeen, isTrue,
          reason: 'charge cycle should occur within an hour');
    });
  });
}
