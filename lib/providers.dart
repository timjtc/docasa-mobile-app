import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ble/docasa_connection.dart';
import 'ble/fake/fake_docasa_connection.dart';
import 'data/db/database.dart';
import 'data/filter_health.dart';
import 'data/history_repository.dart';
import 'data/notifications.dart';
import 'data/recording_service.dart';
import 'data/settings_repository.dart';
import 'protocol/models.dart';

/// All Riverpod wiring. Phase 4 swaps [connectionProvider]'s implementation to
/// the flutter_blue_plus transport; every consumer stays untouched.

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final connectionProvider = Provider<DocasaConnection>((ref) {
  // Phase 3: device emulator (encode→decode round-trip each tick).
  final c = FakeDocasaConnection();
  ref.onDispose(c.dispose);
  return c;
});

final connectionStateProvider = StreamProvider<DocasaConnectionState>(
    (ref) => ref.watch(connectionProvider).states);

final telemetryProvider = StreamProvider<DocasaTelemetry>(
    (ref) => ref.watch(connectionProvider).telemetry);

/// Null while not connected (UI shows the connect prompt).
final deviceInfoProvider = FutureProvider<DocasaDeviceInfo?>((ref) async {
  final s = ref.watch(connectionStateProvider).value;
  if (s != DocasaConnectionState.connected) return null;
  return ref.watch(connectionProvider).readDeviceInfo();
});

/// Null while not connected (UI shows the connect prompt).
final filterCountersProvider = FutureProvider<FilterCounters?>((ref) async {
  final s = ref.watch(connectionStateProvider).value;
  if (s != DocasaConnectionState.connected) return null;
  return ref.watch(connectionProvider).readFilterCounters();
});

final settingsRepoProvider =
    Provider<SettingsRepository>((ref) => SettingsRepository(ref.watch(dbProvider)));

final settingsProvider =
    NotifierProvider<SettingsController, FilterSettings>(SettingsController.new);

class SettingsController extends Notifier<FilterSettings> {
  @override
  FilterSettings build() {
    // Async-hydrate persisted settings over the defaults.
    final repo = ref.watch(settingsRepoProvider);
    repo.load().then((s) => state = s);
    return const FilterSettings();
  }

  Future<void> update(FilterSettings s) async {
    state = s;
    await ref.read(settingsRepoProvider).save(s);
  }
}

final alertPortProvider =
    Provider<FilterAlertPort>((_) => LocalFilterAlertPort());

final recordingServiceProvider = Provider<RecordingService>((ref) {
  final svc = RecordingService(
    db: ref.watch(dbProvider),
    alerts: ref.watch(alertPortProvider),
  );
  ref.onDispose(svc.dispose);
  return svc;
});

final historyRepoProvider =
    Provider<HistoryRepository>((_) => const HistoryRepository());

/// Bumped whenever recorded history changes (seed/clear/refresh) — the
/// IndexedStack keeps pages mounted, so providers must be told to re-query.
class HistoryEpoch extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final historyEpochProvider =
    NotifierProvider<HistoryEpoch, int>(HistoryEpoch.new);

/// Chart data per (range, metric).
final historyProvider = FutureProvider.autoDispose
    .family<HistorySeries, (HistoryRange, HistoryMetric)>((ref, arg) async {
  ref.watch(historyEpochProvider); // re-query on epoch bump
  return ref
      .watch(historyRepoProvider)
      .load(ref.watch(dbProvider), arg.$1, arg.$2);
});

/// Merged filter-health view (counters + budgets + recent rate estimate).
final filterHealthProvider = FutureProvider<FilterHealth?>((ref) async {
  final counters = ref.watch(filterCountersProvider).value;
  if (counters == null) return null;
  final settings = ref.watch(settingsProvider);
  final rate = await estimateLoadRatePerDay(ref.watch(dbProvider));
  return computeFilterHealth(
    counters: counters,
    budgets: settings.budgets,
    now: DateTime.now(),
    loadRatePerDay: rate,
  );
});
