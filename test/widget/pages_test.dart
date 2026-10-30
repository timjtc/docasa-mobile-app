import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docasa_app/core/format.dart';
import 'package:docasa_app/data/db/database.dart';
import 'package:docasa_app/data/history_seeder.dart';
import 'package:docasa_app/features/dashboard/dashboard_page.dart';
import 'package:docasa_app/features/device/device_page.dart';
import 'package:docasa_app/features/filter/filter_page.dart';
import 'package:docasa_app/features/history/history_page.dart';
import 'package:docasa_app/main.dart';
import 'package:docasa_app/protocol/models.dart';
import 'package:docasa_app/providers.dart';

final DateTime _now = DateTime(2026, 10, 30, 12, 30);

final t = DocasaTelemetry(
  at: _now,
  air: const AirQualitySample(pm1: 9, pm25: 14, pm10: 20, stage: 1),
  env: const EnvironmentSample(temperature: 24.6, humidity: 47.2, vocKOhms: 38.4),
  sys: const SystemStatusSample(
      fanRpm: 0, batteryPct: 84, charging: false, batteryFull: false, batteryVoltage: 15.31),
);

void main() {
  testWidgets('dashboard mirrors telemetry (stage label, PM values, live ts)',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectionStateProvider
              .overrideWith((ref) => Stream.value(DocasaConnectionState.connected)),
          telemetryProvider.overrideWith((ref) => Stream.value(t)),
        ],
        child: const MaterialApp(home: DashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AIR MONITOR'), findsOneWidget);
    expect(find.text('GOOD'), findsOneWidget);
    expect(find.text('14'), findsOneWidget); // PM2.5 hero
    expect(find.text('9'), findsOneWidget); // PM1.0 tile
    expect(find.text('20'), findsOneWidget); // PM10 tile
    expect(find.text('live · updated ${Fmt.time(_now)}'), findsOneWidget);
  });

  testWidgets('system page mirrors LCD page 1 values', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectionStateProvider
              .overrideWith((ref) => Stream.value(DocasaConnectionState.connected)),
          telemetryProvider.overrideWith((ref) => Stream.value(t)),
        ],
        child: const MaterialApp(home: SystemPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SYSTEM STATUS'), findsOneWidget);
    expect(find.text(Fmt.tempC(24.6)), findsOneWidget);
    expect(find.text(Fmt.humidity(47.2)), findsOneWidget);
    expect(find.text(Fmt.vocKOhms(38.4)), findsOneWidget);
    expect(find.text(Fmt.rpm(0)), findsOneWidget);
    expect(find.text('84%'), findsOneWidget);
    expect(find.textContaining(Fmt.volts(15.31)), findsOneWidget);
  });

  testWidgets('filter page computes health from counters', (tester) async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          connectionStateProvider
              .overrideWith((ref) => Stream.value(DocasaConnectionState.connected)),
          filterCountersProvider.overrideWith(
              (ref) async => const FilterCounters(
                  fanSeconds: 10800000, pmWeightedFanSeconds: 74250000, powerOnHours: 3210)),
        ],
        child: const MaterialApp(home: FilterPage()),
      ),
    );
    await tester.pumpAndSettle();

    // fs=10.8e6 of 21.6e9 hour budget (~0.05%) and pwfs=74.25e6 of 540e9 —
    // both tiny → ~100% (99.95 rounds to 100).
    expect(find.text('100%'), findsOneWidget);
    expect(find.textContaining(Fmt.fanSecondsAsHours(10800000)), findsWidgets);
    expect(find.text(Fmt.powerOnHours(3210)), findsOneWidget);
    // The replace/reset card sits below the fold — scroll to it first.
    await tester.scrollUntilVisible(
      find.text('Reset filter counters'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Reset filter counters'), findsOneWidget);
    expect(
        tester
            .widget<OutlinedButton>(find.widgetWithText(
                OutlinedButton, 'Reset filter counters'))
            .enabled,
        isFalse,
        reason: 'reset is Phase-5 gated (D-010)');
  });

  testWidgets('history page renders seeded week with coverage note',
      (tester) async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);
    await const HistorySeeder().seed(db, days: 7);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: const MaterialApp(home: HistoryPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.byType(PieChart), findsOneWidget);
    expect(find.textContaining('Coverage:'), findsOneWidget);
    expect(find.textContaining('Day'), findsWidgets);
  });

  testWidgets('device page shows emulator banner and connect controls',
      (tester) async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: const MaterialApp(home: DevicePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('device emulator'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.text('Seed 7 days'), findsOneWidget);
  });

  testWidgets('app shell boots, auto-connects the emulator, dashboard goes live',
      (tester) async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: const DocasaApp(),
      ),
    );
    // Boot → auto-connect (300 ms) → first 1 Hz tick.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('AIR MONITOR'), findsOneWidget);
    // Deterministic seed → clean air at start → stage GOOD.
    expect(find.text('GOOD'), findsOneWidget);

    // Unmount so the fake connection's periodic timer is disposed cleanly.
    await tester.pumpWidget(const SizedBox());
  });
}
