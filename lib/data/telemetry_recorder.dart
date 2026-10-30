import 'dart:async';

import 'package:drift/drift.dart';

import '../ble/docasa_connection.dart';
import '../protocol/models.dart';
import 'db/database.dart';

/// Buffers complete telemetry frames and batch-inserts them into `raw_samples`
/// (flush at 20 rows or every 5 s — keeps write churn off the 1 Hz path).
class TelemetryRecorder {
  TelemetryRecorder(this._db);

  static const int _flushRows = 20;
  static const Duration _flushInterval = Duration(seconds: 5);

  final AppDatabase _db;
  final List<RawSamplesCompanion> _buffer = [];
  StreamSubscription<DocasaTelemetry>? _sub;
  Timer? _flushTimer;
  int _recorded = 0;

  /// Total rows written since [start].
  int get recorded => _recorded;

  void start(DocasaConnection conn) {
    stop();
    _sub = conn.telemetry.listen(_onTelemetry, onError: (_) {});
    _flushTimer = Timer.periodic(_flushInterval, (_) => flush());
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    flush();
  }

  void _onTelemetry(DocasaTelemetry t) {
    if (!t.complete) return; // wait for all three characteristics
    final a = t.air!, e = t.env!, s = t.sys!;
    _buffer.add(RawSamplesCompanion.insert(
      timeMs: Value(t.at.millisecondsSinceEpoch),
      pm1: a.pm1,
      pm25: a.pm25,
      pm10: a.pm10,
      stage: a.stage,
      temp: e.temperature,
      humidity: e.humidity,
      voc: e.vocKOhms,
      fanRpm: s.fanRpm,
      batteryPct: s.batteryPct,
      charging: s.charging,
      batteryV: s.batteryVoltage,
    ));
    if (_buffer.length >= _flushRows) flush();
  }

  Future<void> flush() async {
    if (_buffer.isEmpty) return;
    final rows = List<RawSamplesCompanion>.of(_buffer);
    _buffer.clear();
    try {
      await _db.batch((b) => b.insertAll(_db.rawSamples, rows));
      _recorded += rows.length;
    } on Exception {
      // A rare primary-key collision (same ms) drops the batch — acceptable at
      // 1 Hz; never let a DB hiccup kill the recording stream.
    }
  }
}
