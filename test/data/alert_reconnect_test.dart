import 'dart:async';

import 'package:drift/native.dart';
import 'package:docasa_app/ble/docasa_connection.dart';
import 'package:docasa_app/data/db/database.dart';
import 'package:docasa_app/data/recording_service.dart';
import 'package:docasa_app/data/notifications.dart';
import 'package:docasa_app/data/settings_repository.dart';
import 'package:docasa_app/protocol/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// RecordingService alert-cadence verification (D-021 + D-035):
/// the alert presents on every fresh (re)connect even inside the 24 h
/// re-alert window, while routine evaluations stay capped.

/// Degraded story: ST 2..4 sum ≈98% of the D-037 budget (4,000 h) → ~2% health.
const _degraded = FilterCounters(
  fanSeconds: 25_200,
  pmWeightedFanSeconds: 37_000,
  powerOnHours: 2,
  stageSeconds: [50_000, 22_000, 11_100_000, 2_900_000, 112_000],
);

class CapturingAlerts implements FilterAlertPort {
  final calls = <double>[];
  @override
  Future<void> showFilterLow(double healthPct) async => calls.add(healthPct);
}

/// Connection whose connect() emits `connected` — models the boot
/// auto-connect and the user-driven Connect/Reconnect flow.
class ReconnectableConnection implements DocasaConnection {
  final _states = StreamController<DocasaConnectionState>.broadcast();
  int connects = 0;

  @override
  Stream<DocasaConnectionState> get states => _states.stream;
  @override
  Stream<DocasaTelemetry> get telemetry =>
      const Stream<DocasaTelemetry>.empty();
  @override
  Future<DocasaDeviceInfo> readDeviceInfo() async =>
      const DocasaDeviceInfo(
          manufacturer: 'DOCASA',
          model: 'DOCASA Air Purifier',
          firmwareRevision: '4.2.1',
          hardwareRevision: 'test');
  @override
  Future<FilterCounters> readFilterCounters() async => _degraded;
  @override
  Future<void> syncTime() async {}
  @override
  Future<void> resetFilter() async {}
  @override
  Future<void> connect() async {
    connects++;
    _states.add(DocasaConnectionState.connected);
  }

  @override
  Future<void> disconnect() async {}
  @override
  void dispose() => _states.close();
}

void main() {
  test('a fresh (re)connect re-surfaces degraded health inside the '
      '24 h cap (D-035)', () async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SettingsRepository(db);
    await repo.save((await repo.load()).copyWith(
      // The modal was presented moments ago — the daily cap alone would
      // suppress a routine evaluation.
      lastAlertMs: DateTime.now().millisecondsSinceEpoch,
    ));

    final conn = ReconnectableConnection();
    final alerts = CapturingAlerts();
    final svc = RecordingService(db: db, alerts: alerts);
    addTearDown(svc.dispose);

    await svc.start(conn); // auto-connect → freshConnect evaluation
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(conn.connects, 1);
    expect(alerts.calls, hasLength(1),
        reason: 'connect is an alert trigger — bypasses the cap (D-035)');
    expect(alerts.calls.single, lessThan(10.0),
        reason: 'surfaces the degraded health, not just any health');
  });

  test('routine evaluations stay capped right after a presentation',
      () async {
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);
    final conn = ReconnectableConnection();
    final alerts = CapturingAlerts();
    final svc = RecordingService(db: db, alerts: alerts);
    addTearDown(svc.dispose);

    await svc.start(conn); // boot eval presents + stamps lastAlertMs = now
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(alerts.calls, hasLength(1));

    await svc.evaluateNow(); // timer-equivalent tick, freshConnect: false
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(alerts.calls, hasLength(1),
        reason: 'within 24 h — no re-presentation from routine ticks');
  });
}
