import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
part 'app_database.g.dart';

class LocalEntities extends Table {
  TextColumn get id => text()();
  TextColumn get entityName => text()();
  TextColumn get payload => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get localUpdatedAt => dateTime()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id, entityName};
}

class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get entityName => text()();
  TextColumn get recordId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [LocalEntities, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'sigp_plus'));
  @override
  int get schemaVersion => 1;
}
