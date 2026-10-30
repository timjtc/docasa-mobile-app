import 'dart:async';
// ignore_for_file: use_initializing_formals, prefer_initializing_formals

import '../ble/docasa_connection.dart';
import '../protocol/models.dart';
import 'db/database.dart';
import 'filter_health.dart';
import 'history_compactor.dart';
import 'notifications.dart';
import 'settings_repository.dart';
import 'telemetry_recorder.dart';

/// Orchestrates the app-side services against one [DocasaConnection]:
/// records telemetry while connected, compacts history periodically, and
/// evaluates the low-filter alert (Phase 4 wires the notification permission
/// flow — see D-010/notes in notifications.dart).
class RecordingService {
  RecordingService({
    required AppDatabase db,
    required FilterAlertPort alerts,
    DateTime Function() now = _defaultNow,
  })  : _db = db,
        _alerts = alerts,
        _now = now,
        recorder = TelemetryRecorder(db);

  static DateTime _defaultNow() => DateTime.now();

  final AppDatabase _db;
  final FilterAlertPort _alerts;
  final DateTime Function() _now;

  final TelemetryRecorder recorder;
  final HistoryCompactor compactor = const HistoryCompactor();
  late final SettingsRepository settings = SettingsRepository(_db);

  StreamSubscription<DocasaConnectionState>? _stateSub;
  Timer? _compactTimer;
  Timer? _alertTimer;

  bool _started = false;

  /// Wires everything to [conn] and auto-connects (Phase 3 fake drives the
  /// app immediately; Phase 4 may make connection user-triggered).
  Future<void> start(DocasaConnection conn) async {
    if (_started) return;
    _started = true;
    await compactor.run(_db); // settle aggregates from previous sessions
    _stateSub = conn.states.listen((s) {
      if (s == DocasaConnectionState.connected) {
        recorder.start(conn);
        _onConnected(conn);
      } else {
        recorder.stop();
        _compactTimer?.cancel();
        _compactTimer = null;
        _alertTimer?.cancel();
        _alertTimer = null;
      }
    });
    unawaited(conn.connect());
  }

  Future<void> _onConnected(DocasaConnection conn) async {
    // Initial counters read + alert evaluation (Contract §6.1 handshake).
    await _evaluateAlerts(conn);
    _compactTimer ??= Timer.periodic(
      const Duration(seconds: 60),
      (_) => unawaited(compactor.run(_db)),
    );
    _alertTimer ??= Timer.periodic(
      const Duration(minutes: 5),
      (_) => unawaited(_evaluateAlerts(conn)),
    );
  }

  Future<void> _evaluateAlerts(DocasaConnection conn) async {
    try {
      final counters = await conn.readFilterCounters();
      final s = await settings.load();
      final rate = await estimateLoadRatePerDay(_db);
      final health = computeFilterHealth(
        counters: counters,
        budgets: s.budgets,
        now: _now(),
        loadRatePerDay: rate,
      );
      final nowMs = _now().millisecondsSinceEpoch;
      if (FilterAlertDecision.shouldNotify(
        healthPct: health.pct,
        thresholdPct: s.alertThresholdPct,
        lastAlertMs: s.lastAlertMs,
        nowMs: nowMs,
        connected: true,
      )) {
        await _alerts.showFilterLow(health.pct);
        await settings.save(s.copyWith(lastAlertMs: nowMs));
      }
    } on Exception {
      // Counters read or DB hiccup — skip this evaluation round.
    }
  }

  void dispose() {
    _stateSub?.cancel();
    _compactTimer?.cancel();
    _alertTimer?.cancel();
    recorder.stop();
  }
}
