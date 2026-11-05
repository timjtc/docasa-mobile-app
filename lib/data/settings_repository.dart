import 'db/database.dart';
import 'filter_health.dart';

/// User-tunable app settings persisted in the `app_settings` KV table.
class FilterSettings {
  const FilterSettings({
    this.budgets = const FilterBudgets(),
    this.basis = FilterBasis.dirtyAir, // installed default (D-027)
    this.sensitivity = FilterSensitivity.normal,
    this.alertThresholdPct = 10,
    this.lastAlertMs = 0,
    this.filterAlertAckMs = 0,
  });

  final FilterBudgets budgets;

  /// Which replacement basis the Filter page computes health with (D-027).
  final FilterBasis basis;

  /// Budget multiplier scale shared by both bases (D-027).
  final FilterSensitivity sensitivity;

  /// Fire the replacement alert when health ≤ threshold (percent).
  final int alertThresholdPct;

  /// Last time a low-filter alert fired (ms epoch) — re-alert at most daily.
  final int lastAlertMs;

  /// The user last deferred ("replace later") — the modal reminds at most
  /// once/day afterwards (presentation cap is [lastAlertMs]).
  final int filterAlertAckMs;

  FilterSettings copyWith({
    FilterBudgets? budgets,
    FilterBasis? basis,
    FilterSensitivity? sensitivity,
    int? alertThresholdPct,
    int? lastAlertMs,
    int? filterAlertAckMs,
  }) =>
      FilterSettings(
        budgets: budgets ?? this.budgets,
        basis: basis ?? this.basis,
        sensitivity: sensitivity ?? this.sensitivity,
        alertThresholdPct: alertThresholdPct ?? this.alertThresholdPct,
        lastAlertMs: lastAlertMs ?? this.lastAlertMs,
        filterAlertAckMs: filterAlertAckMs ?? this.filterAlertAckMs,
      );
}

class SettingsRepository {
  const SettingsRepository(this._db);

  final AppDatabase _db;

  static const _kHourBudget = 'filter.hourBudgetRpmS';
  static const _kLoadBudget = 'filter.loadBudgetRpmUgS';
  static const _kBasis = 'filter.basis';
  static const _kSensitivity = 'filter.sensitivity';
  static const _kThreshold = 'filter.alertThresholdPct';
  static const _kLastAlert = 'filter.lastAlertMs';
  static const _kAck = 'filter.alertAckMs';

  Future<FilterSettings> load() async {
    final kv = <String, String>{
      for (final r in await (_db.select(_db.appSettings).get()))
        r.key: r.value,
    };
    return FilterSettings(
      budgets: FilterBudgets(
        hourBudgetRpmS:
            int.tryParse(kv[_kHourBudget] ?? '') ?? const FilterBudgets().hourBudgetRpmS,
        loadBudgetRpmUgS:
            int.tryParse(kv[_kLoadBudget] ?? '') ?? const FilterBudgets().loadBudgetRpmUgS,
      ),
      basis: SettingsRepository.enumBasisByName(kv[_kBasis]) ??
          FilterBasis.dirtyAir,
      sensitivity:
          SettingsRepository.enumSensitivityByName(kv[_kSensitivity]) ??
              FilterSensitivity.normal,
      alertThresholdPct:
          int.tryParse(kv[_kThreshold] ?? '') ?? 10,
      lastAlertMs: int.tryParse(kv[_kLastAlert] ?? '') ?? 0,
      filterAlertAckMs: int.tryParse(kv[_kAck] ?? '') ?? 0,
    );
  }

  Future<void> save(FilterSettings s) => _db.transaction(() async {
        await _put(_kHourBudget, s.budgets.hourBudgetRpmS.toString());
        await _put(_kLoadBudget, s.budgets.loadBudgetRpmUgS.toString());
        await _put(_kBasis, s.basis.name);
        await _put(_kSensitivity, s.sensitivity.name);
        await _put(_kThreshold, s.alertThresholdPct.toString());
        await _put(_kLastAlert, s.lastAlertMs.toString());
        await _put(_kAck, s.filterAlertAckMs.toString());
      });

  Future<void> _put(String key, String value) async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: key, value: value),
        );
  }

  static FilterBasis? enumBasisByName(String? name) {
    for (final b in FilterBasis.values) {
      if (b.name == name) return b;
    }
    return null;
  }

  static FilterSensitivity? enumSensitivityByName(String? name) {
    for (final s in FilterSensitivity.values) {
      if (s.name == name) return s;
    }
    return null;
  }

  // --- Offline-sync water-marks (Contract v1.1 §10.3, D-028) ---------------

  /// Last consumed slot for a device boot: `sync.<bootId>` → `slot|anchorMs`.
  static String syncKey(int bootId) => 'sync.$bootId';

  Future<(int slot, int anchorMs)?> loadSyncWatermark(int bootId) async {
    final v = await (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(syncKey(bootId))))
        .getSingleOrNull();
    if (v == null) return null;
    final parts = v.value.split('|');
    if (parts.length != 2) return null;
    final slot = int.tryParse(parts[0]);
    final anchor = int.tryParse(parts[1]);
    if (slot == null || anchor == null) return null;
    return (slot, anchor);
  }

  Future<void> saveSyncWatermark(int bootId, int slot, int anchorMs) =>
      _put(syncKey(bootId), '$slot|$anchorMs');

  /// Most recent stored water-mark across ALL boots (largest anchor wins —
  /// the first drain arm happens before the device reports its boot id,
  /// §10.3). Returns `(lastSlot, bootId)` or null.
  Future<(int, int)?> lastSyncWatermarkAny() async {
    final rows = await _db
        .customSelect("SELECT key, value FROM app_settings WHERE key LIKE 'sync.%'")
        .get();
    int? bestSlot;
    int? bestBoot;
    int? bestAnchor;
    for (final r in rows) {
      final boot = int.tryParse(r.read<String>('key').substring('sync.'.length));
      if (boot == null) continue;
      final parts = r.read<String>('value').split('|');
      if (parts.length != 2) continue;
      final a = int.tryParse(parts[1]);
      if (a == null) continue;
      if (bestAnchor == null || a > bestAnchor) {
        bestAnchor = a;
        bestSlot = int.tryParse(parts[0]) ?? 0;
        bestBoot = boot;
      }
    }
    if (bestSlot == null || bestBoot == null) return null;
    return (bestSlot, bestBoot);
  }
}
