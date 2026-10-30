import 'package:docasa_app/ble/fake/fake_docasa_connection.dart';
import 'package:docasa_app/protocol/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fake connection drops out of range on a schedule and reconnects',
      (tester) async {
    final conn = FakeDocasaConnection();
    final states = <DocasaConnectionState>[];
    conn.states.listen(states.add);
    var ticks = 0;
    conn.telemetry.listen((_) => ticks++);

    conn.connect();
    await tester.pump(const Duration(milliseconds: 400)); // handshake
    expect(conn.timeSynced, isTrue);
    expect(states.last, DocasaConnectionState.connected);
    expect(ticks, 0); // first 1 Hz tick lands at t=1.3 s

    await tester.pump(const Duration(seconds: 90)); // uptime tick 90 → outage
    expect(states.last, DocasaConnectionState.disconnected);
    expect(ticks, 89); // ticks 1..89 s; tick 90 starts the outage

    await tester.pump(const Duration(seconds: 7)); // 5 s offline + reconnect
    expect(states.last, DocasaConnectionState.connected);
    expect(ticks, 90); // first post-reconnect tick ~1.3 s after connect

    expect(
        states,
        containsAllInOrder(<DocasaConnectionState>[
          DocasaConnectionState.connected,
          DocasaConnectionState.disconnected,
          DocasaConnectionState.connected,
        ]));
    conn.dispose(); // body must end with zero pending timers (flutter_test invariant)
  });
}
