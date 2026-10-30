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
])
class AppDatabase extends _$AppDatabase {
  /// Production: file-backed, background isolate.
  AppDatabase() : super(_open());

  /// Tests: in-memory.
  AppDatabase.test(super.e);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _open() => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'docasa.db'));
      return NativeDatabase.createInBackground(file);
    });
