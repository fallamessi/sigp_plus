import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();
  Database? _database;

  Future<void> initialize() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _database ??= await _open();
  }

  Future<Database> get database async {
    if (_database == null) await initialize();
    return _database!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationSupportDirectory();
    final dbPath = p.join(dir.path, 'sigp_plus_offline.db');
    return openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE entity_cache(
            entity TEXT NOT NULL,
            record_id TEXT NOT NULL,
            payload TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY(entity, record_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE sync_queue(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity TEXT NOT NULL,
            record_id TEXT NOT NULL,
            operation TEXT NOT NULL,
            payload TEXT,
            created_at TEXT NOT NULL,
            attempts INTEGER NOT NULL DEFAULT 0,
            last_error TEXT
          )
        ''');
        await db.execute('CREATE INDEX idx_sync_queue_created ON sync_queue(created_at)');
      },
    );
  }

  Future<List<Map<String, dynamic>>> readEntity(String entity, {String search = ''}) async {
    final db = await database;
    final rows = await db.query('entity_cache', where: 'entity = ? AND deleted = 0', whereArgs: [entity], orderBy: 'updated_at DESC');
    final needle = search.trim().toLowerCase();
    return rows.map((row) => Map<String, dynamic>.from(jsonDecode(row['payload']! as String) as Map)).where((item) {
      if (needle.isEmpty) return true;
      return item.values.any((value) => value?.toString().toLowerCase().contains(needle) ?? false);
    }).toList();
  }

  Future<void> cacheMany(String entity, List<Map<String, dynamic>> items) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toUtc().toIso8601String();
    for (final item in items) {
      final id = item['id']?.toString();
      if (id == null || id.isEmpty) continue;
      batch.insert('entity_cache', {'entity': entity, 'record_id': id, 'payload': jsonEncode(item), 'updated_at': item['updated_at']?.toString() ?? now, 'deleted': 0}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertLocal(String entity, Map<String, dynamic> item, {required String operation}) async {
    final db = await database;
    final id = item['id']!.toString();
    final now = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      await txn.insert('entity_cache', {'entity': entity, 'record_id': id, 'payload': jsonEncode(item), 'updated_at': now, 'deleted': 0}, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('sync_queue', {'entity': entity, 'record_id': id, 'operation': operation, 'payload': jsonEncode(item), 'created_at': now});
    });
  }

  Future<void> markDeleted(String entity, String id, {bool enqueue = true}) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      await txn.update('entity_cache', {'deleted': 1, 'updated_at': now}, where: 'entity = ? AND record_id = ?', whereArgs: [entity, id]);
      if (enqueue) {
        await txn.insert('sync_queue', {'entity': entity, 'record_id': id, 'operation': 'delete', 'created_at': now});
      }
    });
  }

  Future<List<Map<String, Object?>>> pendingOperations() async => (await database).query('sync_queue', orderBy: 'created_at ASC');
  Future<void> removeOperation(int id) async => (await database).delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  Future<void> markOperationFailed(int id, Object error) async => (await database).rawUpdate('UPDATE sync_queue SET attempts = attempts + 1, last_error = ? WHERE id = ?', [error.toString(), id]);
  Future<int> pendingCount() async => Sqflite.firstIntValue(await (await database).rawQuery('SELECT COUNT(*) FROM sync_queue')) ?? 0;
}
