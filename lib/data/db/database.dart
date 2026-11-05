import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  RawSamples,
  MinuteAggregates,
  HourAggregates,
  AppSettings,
  FilterEvents,
  DeviceWindows, // v1.1 (D-028) — schema v2
])
class AppDatabase extends _$AppDatabase {
  /// Production: file-backed, background isolate.
  AppDatabase() : super(_open());

  /// Tests: in-memory.
  AppDatabase.test(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2 (D-028): device offline-history windows.
          if (from < 2) await m.createTable(deviceWindows);
        },
      );
}

LazyDatabase _open() => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'docasa.db'));
      return NativeDatabase.createInBackground(file);
    });
