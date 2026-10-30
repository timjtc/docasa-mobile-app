import 'db/database.dart';
import 'filter_health.dart';

/// User-tunable app settings persisted in the `app_settings` KV table.
class FilterSettings {
  const FilterSettings({
    this.budgets = const FilterBudgets(),
    this.alertThresholdPct = 10,
    this.lastAlertMs = 0,
  });

  final FilterBudgets budgets;

  /// Fire the replacement alert when health ≤ threshold (percent).
  final int alertThresholdPct;

  /// Last time a low-filter alert fired (ms epoch) — re-alert at most daily.
  final int lastAlertMs;

  FilterSettings copyWith({
    FilterBudgets? budgets,
    int? alertThresholdPct,
    int? lastAlertMs,
  }) =>
      FilterSettings(
        budgets: budgets ?? this.budgets,
        alertThresholdPct: alertThresholdPct ?? this.alertThresholdPct,
        lastAlertMs: lastAlertMs ?? this.lastAlertMs,
      );
}

class SettingsRepository {
  const SettingsRepository(this._db);

  final AppDatabase _db;

  static const _kHourBudget = 'filter.hourBudgetRpmS';
  static const _kLoadBudget = 'filter.loadBudgetRpmUgS';
  static const _kThreshold = 'filter.alertThresholdPct';
  static const _kLastAlert = 'filter.lastAlertMs';

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
      alertThresholdPct:
          int.tryParse(kv[_kThreshold] ?? '') ?? 10,
      lastAlertMs: int.tryParse(kv[_kLastAlert] ?? '') ?? 0,
    );
  }

  Future<void> save(FilterSettings s) => _db.transaction(() async {
        await _put(_kHourBudget, s.budgets.hourBudgetRpmS.toString());
        await _put(_kLoadBudget, s.budgets.loadBudgetRpmUgS.toString());
        await _put(_kThreshold, s.alertThresholdPct.toString());
        await _put(_kLastAlert, s.lastAlertMs.toString());
      });

  Future<void> _put(String key, String value) async {
    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: key, value: value),
        );
  }
}
