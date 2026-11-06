import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docasa_app/ble/docasa_connection.dart';
import 'package:docasa_app/data/db/database.dart';
import 'package:docasa_app/data/filter_health.dart';
import 'package:docasa_app/data/history_compactor.dart';
import 'package:docasa_app/data/history_repository.dart';
import 'package:docasa_app/data/notifications.dart';
import 'package:docasa_app/data/settings_repository.dart';
import 'package:docasa_app/data/telemetry_recorder.dart';
import 'package:docasa_app/protocol/models.dart';

AppDatabase newDb() => AppDatabase.test(NativeDatabase.memory());

const minute = 60 * 1000;
const hour = 60 * minute;
const day = 24 * hour;

RawSamplesCompanion row(int ms, {int pm25 = 10, int stage = 1}) =>
    RawSamplesCompanion.insert(
      timeMs: Value(ms),
      pm1: (pm25 * 0.65).round(),
      pm25: pm25,
      pm10: (pm25 * 1.45).round(),
      stage: stage,
      temp: 24.0,
      humidity: 47.0,
      voc: 40.0,
      fanRpm: stage == 1 ? 0 : stage * 1000,
      batteryPct: 80,
      charging: false,
      batteryV: 15.2,
    );

MinuteAggregatesCompanion minuteRow(int ms, {int count = 60}) =>
    MinuteAggregatesCompanion.insert(
      minuteStartMs: Value(ms),
      pm1: 3.0,
      pm25: 5.0,
      pm10: 7.0,
      temp: 24.0,
      humidity: 47.0,
      voc: 40.0,
      fanRpm: 1000.0,
      batteryPct: 80.0,
      batteryV: 15.2,
      stageMax: 1,
      stage1Count: count,
      stage2Count: 0,
      stage3Count: 0,
      stage4Count: 0,
      stage5Count: 0,
      sampleCount: count,
    );

HourAggregatesCompanion hourRow(int ms) => HourAggregatesCompanion.insert(
      hourStartMs: Value(ms),
      pm1: 3.0,
      pm25: 5.0,
      pm10: 7.0,
      temp: 24.0,
      humidity: 47.0,
      voc: 40.0,
      fanRpm: 1000.0,
      batteryPct: 80.0,
      batteryV: 15.2,
      stageMax: 1,
      stage1Count: 3600,
      stage2Count: 0,
      stage3Count: 0,
      stage4Count: 0,
      stage5Count: 0,
      sampleCount: 3600,
    );

Future<int> nOf(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').get())
        .first
        .read<int>('n');

int floorMin(int ms) => ms - ms % minute;

void main() {
  late AppDatabase db;
  setUp(() => db = newDb());
  tearDown(() async => db.close());

  test('history metrics no longer expose Fan/Battery graphs (D-032)', () {
    expect(
      HistoryMetric.values.map((m) => m.name),
      isNot(
          containsAll(<Matcher>[equals('fan_rpm'), equals('battery_pct')])),
    );
  });

  test('minute aggregation: averages, stage counts, max, sample count',
      () async {
    final m0 = floorMin(1700000000000);
    await db.batch((b) {
      for (var i = 0; i < 60; i++) {
        b.insert(db.rawSamples, row(m0 + i * 1000, pm25: 10, stage: 1));
      }
      for (var i = 0; i < 60; i++) {
        b.insert(
            db.rawSamples, row(m0 + minute + i * 1000, pm25: 40, stage: 2));
      }
    });

    await const HistoryCompactor().run(db, nowMs: m0 + 2 * minute);

    final rows = await db.select(db.minuteAggregates).get();
    expect(rows.length, 2);
    final first = rows.firstWhere((r) => r.minuteStartMs == m0);
    expect(first.pm25, closeTo(10, 0.001));
    expect(first.stageMax, 1);
    expect(first.stage1Count, 60);
    expect(first.sampleCount, 60);
    final second = rows.firstWhere((r) => r.minuteStartMs == m0 + minute);
    expect(second.pm25, closeTo(40, 0.001));
    expect(second.stageMax, 2);
    expect(second.stage2Count, 60);
  });

  test('hour aggregation is weighted by per-minute sample counts', () async {
    final h0 = 1700000000000 - 1700000000000 % hour;
    // 60 samples of pm25=20 + 30 samples of pm25=50 → weighted avg = 30.
    await db.batch((b) {
      for (var i = 0; i < 60; i++) {
        b.insert(db.rawSamples, row(h0 + i * 1000, pm25: 20, stage: 1));
      }
      for (var i = 0; i < 30; i++) {
        b.insert(db.rawSamples, row(h0 + minute + i * 1000, pm25: 50, stage: 3));
      }
    });
    await const HistoryCompactor().run(db, nowMs: h0 + hour);

    final hours = await db.select(db.hourAggregates).get();
    expect(hours.length, 1);
    expect(hours.first.hourStartMs, h0);
    expect(hours.first.pm25, closeTo(30, 0.01));
    expect(hours.first.stageMax, 3);
    expect(hours.first.stage1Count, 60);
    expect(hours.first.stage3Count, 30);
    expect(hours.first.sampleCount, 90);
  });

  test('retention pruning per D-012 (24 h raw / 7 d minute / 90 d hour)',
      () async {
    final now = 1700000000000;
    await db.batch((b) {
      b.insert(db.rawSamples, row(now - 25 * hour, pm25: 5)); // older than 24 h
      b.insert(db.minuteAggregates, minuteRow(now - 8 * day)); // older than 7 d
      b.insert(db.hourAggregates, hourRow(now - 91 * day)); // older than 90 d
    });

    await const HistoryCompactor().run(db, nowMs: now);

    expect(await nOf(db, 'raw_samples'), 0, reason: 'raw pruned at 24 h');
    expect(await nOf(db, 'minute_aggregates'), 0,
        reason: 'minute pruned at 7 d');
    expect(await nOf(db, 'hour_aggregates'), 0, reason: 'hour pruned at 90 d');
  });

  test('day view: gaps are null points, coverage reflects missing minutes',
      () async {
    final now = 1700000000000;
    final windowStart = now - 24 * hour;
    final firstBucket = floorMin(windowStart);
    await db.batch((b) {
      for (var m = 0; m < 5; m++) {
        if (m == 2) continue; // gap minute
        for (var i = 0; i < 60; i++) {
          b.insert(db.rawSamples, row(firstBucket + m * minute + i * 1000));
        }
      }
    });
    await const HistoryCompactor().run(db, nowMs: now);

    final s = await const HistoryRepository()
        .load(db, HistoryRange.day, HistoryMetric.pm25, nowMs: now);

    expect(s.bucketCount, inInclusiveRange(24 * 60 - 3, 24 * 60 + 3));
    final idx0 = (firstBucket - s.windowStartMs) ~/ minute;
    expect(s.points[idx0], isNotNull);
    expect(s.points[idx0 + 2], isNull, reason: 'missing minute is a gap');
    expect(s.points[idx0 + 4], isNotNull);
    expect(s.coverage, lessThan(1));
    expect(s.stageCounts[0], 4 * 60);
  });

  test('week view reads the hour tier', () async {
    final now = 1700000000000;
    final h0 = now - now % hour - 30 * hour;
    await db.batch((b) {
      for (var h = 0; h < 26; h++) {
        for (var i = 0; i < 3600; i++) {
          b.insert(db.rawSamples,
              row(h0 + h * hour + i * 1000, pm25: 30, stage: 2));
        }
      }
    });
    await const HistoryCompactor().run(db, nowMs: now);

    final s = await const HistoryRepository()
        .load(db, HistoryRange.week, HistoryMetric.pm25, nowMs: now);
    expect(s.bucketCount, inInclusiveRange(24 * 7 - 3, 24 * 7 + 3));
    expect(s.coverage, greaterThan(0.1));
    expect(s.stageCounts[1], greaterThan(0));
    for (final p in s.points) {
      if (p != null) expect(p, closeTo(30, 0.01));
    }
  });

  test('month view reads 30 days of the hour tier', () async {
    final now = 1700000000000;
    final a = (now - 2 * hour) ~/ hour * hour;
    final m = (now - 4 * day) ~/ hour * hour;
    final c = (now - 29 * day) ~/ hour * hour;
    await db.batch((b) {
      b.insert(db.hourAggregates, hourRow(a));
      b.insert(db.hourAggregates, hourRow(m));
      b.insert(db.hourAggregates, hourRow(c));
    });

    final s = await const HistoryRepository()
        .load(db, HistoryRange.month, HistoryMetric.pm25, nowMs: now);
    expect(s.bucketCount, inInclusiveRange(29 * 24, 30 * 24 + 2));
    expect(s.points[(a - s.windowStartMs) ~/ hour], isNotNull);
    expect(s.points[(m - s.windowStartMs) ~/ hour], isNotNull);
    expect(s.points[(c - s.windowStartMs) ~/ hour], closeTo(5, 0.01));
    expect(s.coverage, lessThan(0.1));
    expect(s.stageCounts[0], 3 * 3600);
  });

  test('TelemetryRecorder buffers and flushes complete frames', () async {
    final conn = ManualConnection();
    final rec = TelemetryRecorder(db);
    rec.start(conn);

    final base = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    for (var i = 0; i < 25; i++) {
      conn.emit(base.add(Duration(seconds: i)));
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await rec.flush();

    expect(await nOf(db, 'raw_samples'), 25);
    rec.stop();
  });

  test('settings round-trip', () async {
    final repo = SettingsRepository(db);
    expect((await repo.load()).alertThresholdPct, 10); // defaults

    await repo.save((await repo.load()).copyWith(
      budgets: const FilterBudgets(
          hourBudgetRpmS: 123456, loadBudgetRpmUgS: 654321),
      alertThresholdPct: 15,
      lastAlertMs: 42,
    ));
    final s = await repo.load();
    expect(s.budgets.hourBudgetRpmS, 123456);
    expect(s.budgets.loadBudgetRpmUgS, 654321);
    expect(s.alertThresholdPct, 15);
    expect(s.lastAlertMs, 42);
  });

  test('alert decision logic (at most daily, only while connected)', () {
    bool should({
      required double pct,
      required int last,
      required int now,
      bool connected = true,
      int threshold = 10,
    }) =>
        FilterAlertDecision.shouldNotify(
            healthPct: pct,
            thresholdPct: threshold,
            lastAlertMs: last,
            nowMs: now,
            connected: connected);

    expect(should(pct: 9.5, last: 0, now: day), isTrue);
    expect(should(pct: 9.5, last: day - 1000, now: day), isFalse,
        reason: 'already alerted < 24 h ago');
    expect(should(pct: 11, last: 0, now: day), isFalse,
        reason: 'above threshold');
    expect(should(pct: 9.5, last: 0, now: day, connected: false), isFalse);
  });
}

/// Manually-driven connection for recorder tests (no timers).
class ManualConnection implements DocasaConnection {
  final _telemetry = StreamController<DocasaTelemetry>.broadcast();

  void emit(DateTime at) => _telemetry.add(DocasaTelemetry(
        at: at,
        air: const AirQualitySample(pm1: 6, pm25: 10, pm10: 14, stage: 1),
        env: const EnvironmentSample(
            temperature: 24.0, humidity: 47.0, vocKOhms: 40.0),
        sys: const SystemStatusSample(
            fanRpm: 0,
            batteryPct: 80,
            charging: false,
            batteryFull: false,
            batteryVoltage: 15.2),
      ));

  @override
  Stream<DocasaConnectionState> get states =>
      const Stream<DocasaConnectionState>.empty();

  @override
  Stream<DocasaTelemetry> get telemetry => _telemetry.stream;

  @override
  Future<DocasaDeviceInfo> readDeviceInfo() async =>
      throw UnimplementedError();

  @override
  Future<FilterCounters> readFilterCounters() async =>
      throw UnimplementedError();

  @override
  Future<void> syncTime() async {}

  @override
  Future<void> resetFilter() async {}

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  void dispose() => _telemetry.close();
}
