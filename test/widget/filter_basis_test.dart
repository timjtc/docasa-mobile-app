import 'package:drift/native.dart';
import 'package:docasa_app/data/db/database.dart';
import 'package:docasa_app/features/device/device_page.dart';
import 'package:docasa_app/features/filter/filter_page.dart';
import 'package:docasa_app/protocol/models.dart';
import 'package:docasa_app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Filter page basis toggle + sensitivity scale (D-027).
void main() {
  final counters = FilterCounters(
    fanSeconds: 10800000,
    pmWeightedFanSeconds: 74250000,
    powerOnHours: 3210,
    stageSeconds: [3_600_000, 250_000, 1000, 60, 0],
  );

  Future<BuildContext?> pumpPage(WidgetTester tester, AppDatabase db) async {
    BuildContext? ctx;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
        connectionStateProvider.overrideWith(
            (ref) => Stream.value(DocasaConnectionState.connected)),
        filterCountersProvider.overrideWith((ref) async => counters),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return const FilterPage();
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return ctx;
  }

  testWidgets('dirty-air basis is the installed default and raw counters '
      'are not on the Filter tab', (tester) async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);
    await pumpPage(tester, db);

    // Default basis shows on the health card; the raw per-stage counters
    // moved to the Device tab behind dev options (user request).
    expect(find.textContaining('Consumption driven by dirty-air exposure'),
        findsOneWidget);
    expect(find.text('Dirty-air time'), findsNothing);
    expect(find.text('Device counters'), findsNothing);
  });

  testWidgets('device counters moved to the Device tab behind dev options',
      (tester) async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
        connectionStateProvider.overrideWith(
            (ref) => Stream.value(DocasaConnectionState.connected)),
        filterCountersProvider.overrideWith((ref) async => counters),
        deviceInfoProvider.overrideWith((ref) async => const DocasaDeviceInfo(
            manufacturer: 'DOCASA',
            model: 'DOCASA Air Purifier',
            firmwareRevision: '4.2.1',
            hardwareRevision: 'ESP32-WROOM-v3')),
      ],
      child: const MaterialApp(home: DevicePage()),
    ));
    await tester.pumpAndSettle();

    // Dev-gated: absent until the 7-tap unlock (D-030 pattern).
    expect(find.text('Device counters'), findsNothing);
    for (var i = 0; i < 7; i++) {
      await tester.tap(find.textContaining('Device information'));
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpAndSettle();

    // dirty seconds st[2..4]=1000+60+0 = 1060 s → 0.3 h
    await tester.scrollUntilVisible(
      find.textContaining('hours in POOR/BAD/HAZARD air since the filter swap'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('0.3 h'), findsOneWidget,
        reason: 'raw dirty seconds expose the "st" read');
    // Time share prints one line per air level, stage-named, so the long
    // read can no longer squeeze the key label (user-reported bug).
    await tester.scrollUntilVisible(
      find.text('Time share per stage'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('GOOD 3600000s'), findsOneWidget,
        reason: 'first line = GOOD, then FAIR/POOR/BAD/HAZARD');
    expect(find.text('HAZARD 0s'), findsOneWidget);
  });

  testWidgets('switching the basis to Load recomputes from the same '
      'counters', (tester) async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);
    await pumpPage(tester, db);

    await tester.scrollUntilVisible(
      find.text('Load (µg·h)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Load (µg·h)'));
    await tester.pumpAndSettle();
    // pwfs 74.25e6 of 540e9 → ~99.95% — same family; the explainer card swaps
    await tester.scrollUntilVisible(
      find.textContaining('load model used by commercial purifiers'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('load model'), findsOneWidget);
  });
}
