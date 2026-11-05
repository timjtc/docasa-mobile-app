import 'package:drift/drift.dart';

/// Raw 1 Hz telemetry rows (app-recorded while connected — Phase 3/4 reality;
/// on-device offline history arrives in Phase 5).
///
/// `timeMs` is the **phone clock** at arrival — the app is the time authority
/// (Contract §6.7).
class RawSamples extends Table {
  IntColumn get timeMs => integer()();
  IntColumn get pm1 => integer()();
  IntColumn get pm25 => integer()();
  IntColumn get pm10 => integer()();
  IntColumn get stage => integer()();
  RealColumn get temp => real()();
  RealColumn get humidity => real()();
  RealColumn get voc => real()();
  IntColumn get fanRpm => integer()();
  IntColumn get batteryPct => integer()();
  BoolColumn get charging => boolean()();
  RealColumn get batteryV => real()();

  @override
  Set<Column> get primaryKey => {timeMs};
}

/// 1-minute aggregates (day view tier). Per-stage counts keep the
/// stage-distribution donut exact at every tier.
class MinuteAggregates extends Table {
  IntColumn get minuteStartMs => integer()();
  RealColumn get pm1 => real()();
  RealColumn get pm25 => real()();
  RealColumn get pm10 => real()();
  RealColumn get temp => real()();
  RealColumn get humidity => real()();
  RealColumn get voc => real()();
  RealColumn get fanRpm => real()();
  RealColumn get batteryPct => real()();
  RealColumn get batteryV => real()();
  IntColumn get stageMax => integer()();
  IntColumn get stage1Count => integer()();
  IntColumn get stage2Count => integer()();
  IntColumn get stage3Count => integer()();
  IntColumn get stage4Count => integer()();
  IntColumn get stage5Count => integer()();
  IntColumn get sampleCount => integer()();

  @override
  Set<Column> get primaryKey => {minuteStartMs};
}

/// 1-hour aggregates (week/month view tier), weighted by per-minute
/// sample counts so partial minutes don't skew averages.
class HourAggregates extends Table {
  IntColumn get hourStartMs => integer()();
  RealColumn get pm1 => real()();
  RealColumn get pm25 => real()();
  RealColumn get pm10 => real()();
  RealColumn get temp => real()();
  RealColumn get humidity => real()();
  RealColumn get voc => real()();
  RealColumn get fanRpm => real()();
  RealColumn get batteryPct => real()();
  RealColumn get batteryV => real()();
  IntColumn get stageMax => integer()();
  IntColumn get stage1Count => integer()();
  IntColumn get stage2Count => integer()();
  IntColumn get stage3Count => integer()();
  IntColumn get stage4Count => integer()();
  IntColumn get stage5Count => integer()();
  IntColumn get sampleCount => integer()();

  @override
  Set<Column> get primaryKey => {hourStartMs};
}

/// Key-value app settings (filter budgets, alert threshold — D-011/D-012).
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Filter lifecycle events (installs/resets — Phase 5 writes resets from the
/// device; the app records its own view of events here).
class FilterEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get timeMs => integer()();
  TextColumn get kind => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

/// Contract v1.1 §10 — device-side offline envelope windows (10-minute
/// records, 16 B over the air). Keys: (bootId, slot). `windowStartMs` is the
/// **phone-clock** timestamp of the slot start, anchored per §10.3 (the
/// phone is the time authority — Plan §7.13). Fills app-recorded gaps at
/// ingest: PM2.5 envelope + per-stage seconds; device-unmeasured metrics
/// (temp/humidity/voc/fan/battery) are intentionally absent — the history
/// pages show gaps there (honest data, D-028).
class DeviceWindows extends Table {
  IntColumn get bootId => integer()();
  IntColumn get slot => integer()();
  IntColumn get windowStartMs => integer()();
  IntColumn get pmMin => integer()();
  IntColumn get pmMean => integer()();
  IntColumn get pmMax => integer()();
  IntColumn get stage1Sec => integer()();
  IntColumn get stage2Sec => integer()();
  IntColumn get stage3Sec => integer()();
  IntColumn get stage4Sec => integer()();
  IntColumn get stage5Sec => integer()();

  @override
  Set<Column> get primaryKey => {bootId, slot};
}
