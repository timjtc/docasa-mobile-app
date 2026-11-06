import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../ble/fake/fake_generator.dart';
import 'db/database.dart';
import 'history_compactor.dart';

/// Demo tool (Phase 3): generates `days` of plausible history straight into
/// `raw_samples` using the same device emulator, with realistic gaps (device
/// "off" overnight), then compacts. Lets day/week/month charts be demonstrated
/// instantly instead of waiting days of live recording.
class HistorySeeder {
  const HistorySeeder();

  static const int _chunk = 3600;

  Future<void> seed(
    AppDatabase db, {
    int days = 7,
    int seed = 7,
    int? nowMs,
  }) async {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final start =
        now - days * 24 * 3600 * 1000 - (now % 60000); // align to minute
    final gen = FakeDocasaGenerator(seed: seed);

    // Simulated wall-clock per step.
    var t = start;
    final end = now - (now % 60000);
    final buffer = <RawSamplesCompanion>[];

    while (t < end) {
      final localHour = DateTime.fromMillisecondsSinceEpoch(t).hour;
      final deviceOn = localHour >= 7 && localHour < 23; // "off" overnight
      if (deviceOn) {
        final tick = gen.step();
        final a = tick.air, e = tick.env, s = tick.sys;
        buffer.add(RawSamplesCompanion.insert(
          timeMs: Value(t),
          pm1: a.pm1,
          pm25: a.pm25,
          pm10: a.pm10,
          stage: a.stage,
          temp: e.temperature,
          humidity: e.humidity,
          voc: e.vocKOhms,
          fanRpm: s.fanRpm,
          batteryPct: s.batteryPct,
          charging: s.charging,
          batteryV: s.batteryVoltage,
        ));
      }
      t += 1000;
      if (buffer.length >= _chunk) {
        await _insert(db, buffer);
        buffer.clear();
      }
    }
    if (buffer.isNotEmpty) await _insert(db, buffer);
    await const HistoryCompactor().run(db, nowMs: now);
  }

  Future<void> _insert(AppDatabase db, List<RawSamplesCompanion> rows) async {
    try {
      await db.batch((b) => b.insertAll(db.rawSamples, rows));
    } on Exception {
      // ignore duplicate-key batches (demo data)
    }
  }
}

/// What a demo seeding produced — the Device-page dev action pushes these to
/// the device counters (NVS via the §5 dev channel) so the filter-health
/// story runs from the device itself (D-030).
class UsageTotals {
  const UsageTotals({
    required this.fanSeconds,
    required this.pmWeightedFanSeconds,
    required this.powerOnSeconds,
    required this.stageSeconds,
  });

  final int fanSeconds;
  final int pmWeightedFanSeconds;
  final int powerOnSeconds;
  final List<int> stageSeconds;

  int get dirtySeconds => stageSeconds.length >= 5
      ? stageSeconds[2] + stageSeconds[3] + stageSeconds[4]
      : 0;

  @override
  String toString() =>
      'UsageTotals(fs:$fanSeconds pwfs:$pmWeightedFanSeconds '
      'on:$powerOnSeconds st:$stageSeconds)';
}

/// One demo hour under accumulation.
class _HourAcc {
  int pm1Sum = 0;
  int pm25Sum = 0;
  int pm10Sum = 0;
  int minutes = 0;
  final List<int> st = [0, 0, 0, 0, 0]; // seconds per stage in this hour
  int stageMax = 1;
}

/// Developer demo (D-027/D-030, story tuned 2026-11-07): back-fill ~2 months
/// of REALISTIC dirty-skewed history — cleaner morning/evening stretches and
/// ~6 h "off" overnight, so GOOD/FAIR get real hours, but the day still ends
/// majority-POOR+ (≈92 % dirty): the Normal basis lands near 0 % and the
/// replacement alert fires; Sensitive overflows to 0 %. Minute cadence (one
/// row = one full-minute bucket; no raw rows → ~65k rows, cheap). REPLACES
/// the existing timeline; returns the usage totals for the Device-page dev
/// action to write into the device counters (dev channel) so the health
/// basis matches the seeded story.
class TwoMonthSeeder {
  const TwoMonthSeeder();

  static const int days = 60;

  Future<UsageTotals> seed(AppDatabase db, {int? nowMs}) async {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    await wipeHistory(db); // seed REPLACES the timeline (demo semantics)

    final rng = math.Random(7); // deterministic — tests assert ranges
    int fs = 0, pwfs = 0, onSec = 0;
    var on = List<int>.filled(5, 0); // stage seconds
    double tempDrift = 0, humDrift = 0, vocBase = 45;

    final hours = <int, _HourAcc>{};

    final minuteRows = <MinuteAggregatesCompanion>[];
    final lastMinute = now - (now % 60000);
    var minuteStart = now - days * 24 * 3600 * 1000;
    while (minuteStart < lastMinute) {
      final d = DateTime.fromMillisecondsSinceEpoch(minuteStart);
      final minsOfDay = d.hour * 60 + d.minute;
      // Realistic duty: the purifier sleeps only ~6 h (off 00:30–06:30),
      // so the 2-month story fits ~1080 powered hours — enough headroom for
      // the clean stretches below to stay under the dirty budget.
      final deviceOn = !(minsOfDay >= 30 && minsOfDay < 390);
      if (deviceOn) {
        // Cleaner mornings/evenings, dirtier afternoons: the hour bias keeps
        // a realistic rhythm (GOOD/FAIR stretches) while the day still ends
        // majority-dirty.
        var r = rng.nextDouble();
        switch (d.hour) {
          case 7 || 8 || 9 || 21 || 22:
            r -= 0.14; // calm hours — GOOD/FAIR more likely
          case 12 || 13 || 14 || 15 || 16 || 17 || 18:
            r += 0.12; // afternoon smog peak
        }
        final double pm;
        if (r < 0.02) {
          pm = 3 + rng.nextDouble() * 9; // GOOD (stage 1)
        } else if (r < 0.08) {
          pm = 13 + rng.nextDouble() * 22; // FAIR (stage 2)
        } else if (r < 0.25) {
          pm = 36 + rng.nextDouble() * 19; // POOR (stage 3)
        } else if (r < 0.75) {
          pm = 58 + rng.nextDouble() * 90; // BAD (stage 4)
        } else {
          pm = 152 + rng.nextDouble() * 88; // HAZARD (stage 5)
        }
        final pm25 = pm.round();
        final pm1 = (pm25 * 0.65).round();
        final pm10 = (pm25 * 1.45).round();
        final stage = overallStageOf(pm25, pm10, 48); // no VOC bump
        final fan = fanRpmOf(stage);

        fs += fan * 60;
        pwfs += fan * pm25 * 60;
        onSec += 60;
        on[stage - 1] += 60;

        tempDrift = (tempDrift + (rng.nextDouble() - 0.5) * 0.4).clamp(-2.0, 2.0);
        humDrift = (humDrift + (rng.nextDouble() - 0.5) * 1.2).clamp(-10.0, 10.0);
        vocBase = (vocBase + (rng.nextDouble() - 0.5) * 3.0).clamp(20.0, 90.0);

        final hour0 = (minuteStart ~/ 3600000) * 3600000;
        final acc = hours.putIfAbsent(hour0, _HourAcc.new);
        acc.pm1Sum += pm1;
        acc.pm25Sum += pm25;
        acc.pm10Sum += pm10;
        acc.minutes += 1;
        acc.st[stage - 1] += 60;
        if (stage > acc.stageMax) acc.stageMax = stage;

        minuteRows.add(MinuteAggregatesCompanion.insert(
          minuteStartMs: Value(minuteStart),
          pm1: pm1.toDouble(),
          pm25: pm25.toDouble(),
          pm10: pm10.toDouble(),
          temp: 24.5 + tempDrift,
          humidity: 47 + humDrift,
          voc: vocBase,
          fanRpm: fan.toDouble(),
          batteryPct: 80,
          batteryV: 15.1,
          stageMax: stage,
          stage1Count: stage == 1 ? 60 : 0,
          stage2Count: stage == 2 ? 60 : 0,
          stage3Count: stage == 3 ? 60 : 0,
          stage4Count: stage == 4 ? 60 : 0,
          stage5Count: stage == 5 ? 60 : 0,
          sampleCount: 60,
        ));
        if (minuteRows.length >= 1800) {
          await _writeMinutes(db, minuteRows);
          minuteRows.clear();
        }
      }
      minuteStart += 60000;
    }
    if (minuteRows.isNotEmpty) await _writeMinutes(db, minuteRows);

    final hourRows = <HourAggregatesCompanion>[];
    for (final e in hours.entries) {
      final acc = e.value;
      final n = math.max(1, acc.minutes);
      hourRows.add(HourAggregatesCompanion.insert(
        hourStartMs: Value(e.key),
        pm1: acc.pm1Sum / n,
        pm25: acc.pm25Sum / n,
        pm10: acc.pm10Sum / n,
        temp: 24.6,
        humidity: 47.2,
        voc: 45.0,
        fanRpm: 0,
        batteryPct: 80,
        batteryV: 15.1,
        stageMax: acc.stageMax,
        stage1Count: acc.st[0],
        stage2Count: acc.st[1],
        stage3Count: acc.st[2],
        stage4Count: acc.st[3],
        stage5Count: acc.st[4],
        sampleCount: acc.minutes * 60,
      ));
    }
    await _writeHours(db, hourRows);

    return UsageTotals(
      fanSeconds: fs,
      pmWeightedFanSeconds: pwfs,
      powerOnSeconds: onSec,
      stageSeconds: List<int>.of(on),
    );
  }

  Future<void> _writeMinutes(
          AppDatabase db, List<MinuteAggregatesCompanion> rows) =>
      db.batch((b) => b.insertAll(db.minuteAggregates, rows,
          mode: InsertMode.insertOrReplace));

  Future<void> _writeHours(AppDatabase db, List<HourAggregatesCompanion> rows) =>
      db.batch((b) => b.insertAll(db.hourAggregates, rows,
          mode: InsertMode.insertOrReplace));
}
