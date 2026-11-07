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
    // moved to the Device tab behind dev options (user request). Basis
    // switching itself is dev-only now (D-036) — the consumer sees no knob.
    expect(find.textContaining('Consumption driven by dirty-air exposure'),
        findsOneWidget);
    expect(find.text('Dirty-air hours'), findsNothing);
    expect(find.text('Load (µg·h)'), findsNothing);
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

  testWidgets('basis switching moved to Developer options and takes '
      'effect from there (D-036)', (tester) async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);
    // One shared override list + keyed scopes: re-pumping is a fresh scope
    // each time (riverpod updateOverrides asserts on added overrides).
    final overrides = [
      dbProvider.overrideWithValue(db),
      connectionStateProvider.overrideWith(
          (ref) => Stream.value(DocasaConnectionState.connected)),
      filterCountersProvider.overrideWith((ref) async => counters),
      deviceInfoProvider.overrideWith((ref) async => const DocasaDeviceInfo(
          manufacturer: 'DOCASA',
          model: 'DOCASA Air Purifier',
          firmwareRevision: '4.2.1',
          hardwareRevision: 'ESP32-WROOM-v3')),
    ];

    // Consumer view is pinned: no basis control on the Filter tab.
    await tester.pumpWidget(ProviderScope(
      key: const ValueKey('filter1'),
      overrides: overrides,
      child: const MaterialApp(home: FilterPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Dirty-air hours'), findsNothing);
    expect(find.text('Load (µg·h)'), findsNothing);

    // The knob lives in Developer options on the Device tab.
    await tester.pumpWidget(ProviderScope(
      key: const ValueKey('device'),
      overrides: overrides,
      child: const MaterialApp(home: DevicePage()),
    ));
    await tester.pumpAndSettle();
    for (var i = 0; i < 7; i++) {
      await tester.tap(find.textContaining('Device information'));
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Replacement basis (developer)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final loadSeg = find.text('Load (µg·h)');
    await tester.ensureVisible(loadSeg);
    await tester.pumpAndSettle();
    await tester.tap(loadSeg);
    await tester.pumpAndSettle();

    // Back on the Filter tab the choice took effect: the explainer card
    // switches to the load-model wording (settings persist via the DB).
    await tester.pumpWidget(ProviderScope(
      key: const ValueKey('filter2'),
      overrides: overrides,
      child: const MaterialApp(home: FilterPage()),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('weighted by particulate load'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('weighted by particulate load'),
        findsOneWidget,
        reason: 'settings.basis=load persisted through the dev knob');
  });
}
