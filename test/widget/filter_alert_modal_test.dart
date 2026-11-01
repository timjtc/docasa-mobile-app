import 'package:docasa_app/ble/fake/fake_docasa_connection.dart';
import 'package:docasa_app/data/db/database.dart';
import 'package:docasa_app/features/filter/filter_alert_modal.dart';
import 'package:docasa_app/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('alert channel: app visible → modal, unfocused → push', () {
    for (final s in [
      AppLifecycleState.resumed,
      AppLifecycleState.inactive,
    ]) {
      expect(alertShouldUseInAppModal(s), isTrue,
          reason: '$s should raise the in-app modal');
    }
    for (final s in [
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.detached,
    ]) {
      expect(alertShouldUseInAppModal(s), isFalse,
          reason: '$s should send a push instead');
    }
  });

  testWidgets('modal: defer records the ack; replace resets and re-arms',
      (tester) async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);
    // Pre-existing alert state → replace must clear lastAlertMs to 0.
    await db.transaction(() => db.into(db.appSettings).insert(
          AppSettingsCompanion.insert(
              key: 'filter.lastAlertMs', value: '12345'),
        ));
    final conn = FakeDocasaConnection();
    addTearDown(conn.dispose);
    final container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
      connectionProvider.overrideWithValue(conn),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: Placeholder())),
      ),
    );

    showFilterReplaceModal(tester.element(find.byType(Placeholder)));
    await tester.pumpAndSettle();
    expect(find.text('Filter needs replacing'), findsOneWidget);

    await tester.tap(find.text("I'll replace it at a later time"));
    await tester.pumpAndSettle();
    expect(find.text('Filter needs replacing'), findsNothing);
    var s = await container.read(settingsRepoProvider).load();
    expect(s.filterAlertAckMs, greaterThan(0),
        reason: 'ignoring is tracked (ms epoch)');

    showFilterReplaceModal(tester.element(find.byType(Placeholder)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I just replaced the filter'));
    await tester.pumpAndSettle();
    expect(find.text('Filter needs replacing'), findsNothing);
    s = await container.read(settingsRepoProvider).load();
    expect(s.lastAlertMs, 0,
        reason: 'replacement re-arms the daily alert cap');
  });
}
