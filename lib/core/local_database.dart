import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
part 'local_database.g.dart';

class LocalRecords extends Table {
  TextColumn get recordId => text()();
  TextColumn get entity => text()();
  TextColumn get payload => text()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override Set<Column<Object>> get primaryKey => {recordId, entity};
}

class PendingOperations extends Table {
  TextColumn get id => text()();
  TextColumn get entity => text()();
  TextColumn get recordId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  @override Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [LocalRecords, PendingOperations, AppSettings])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(driftDatabase(name: 'sigp_plus'));
  @override int get schemaVersion => 1;
}
