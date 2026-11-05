import 'package:drift/native.dart';
import 'package:docasa_app/data/db/database.dart';
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

  testWidgets('dirty-air basis is the installed default and shows the '
      'dirty-air hours row', (tester) async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);
    await pumpPage(tester, db);

    // dirty seconds st[2..4]=1000+60+0 = 1060 s → 0.3 h
    await tester.scrollUntilVisible(
      find.textContaining('POOR/BAD/HAZARD since replacement'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('0.3 h'), findsOneWidget,
        reason: 'raw dirty seconds expose the "st" read');
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
