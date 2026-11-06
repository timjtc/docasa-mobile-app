import 'package:docasa_app/features/device/device_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// D-033 verification flow: the non-BLE Connect entry shows the same
/// device-selection UI with a mock DOCASA row (name + signal bars).
void main() {
  testWidgets('mock picker lists the mock device and the signal icon',
      (tester) async {
    bool? picked;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                picked = await showMockDevicePicker(context);
              },
              child: const Text('Connect'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    expect(find.text('DOCASA-AirPurifier'), findsOneWidget);
    expect(find.byIcon(Icons.signal_cellular_alt), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('DOCASA-AirPurifier'));
    await tester.pumpAndSettle();
    expect(find.text('Device selection'), findsNothing); // sheet dismissed
    expect(picked, isTrue, reason: 'picking the mock row connects the emulator');
  });
}
