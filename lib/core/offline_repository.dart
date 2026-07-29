import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'local_database.dart';

class OfflineRepository {
  OfflineRepository(this.db, this.supabase);
  final LocalDatabase db;
  final SupabaseClient supabase;

  Stream<List<Map<String, dynamic>>> watch(String entity) {
    final q = db.select(db.localRecords)..where((t) => t.entity.equals(entity) & t.deletedAt.isNull());
    return q.watch().map((rows) => rows.map((e) => {...jsonDecode(e.payload) as Map<String,dynamic>, '_sync_status': e.syncStatus}).toList());
  }

  Future<void> save(String entity, Map<String,dynamic> values, {String? id}) async {
    final recordId = id ?? const Uuid().v4();
    final now = DateTime.now().toUtc();
    final payload = {...values, 'id': recordId, 'updated_at': now.toIso8601String(), 'deleted_at': null};
    await db.into(db.localRecords).insertOnConflictUpdate(LocalRecordsCompanion.insert(
      recordId: recordId, entity: entity, payload: jsonEncode(payload), syncStatus: const Value('pending'), updatedAt: now));
    await _queue(entity, recordId, id == null ? 'upsert' : 'upsert', payload);
  }

  Future<void> remove(String entity, Map<String,dynamic> item) async {
    final id = item['id'].toString();
    final now = DateTime.now().toUtc();
    final payload = {...item, 'deleted_at': now.toIso8601String(), 'updated_at': now.toIso8601String()};
    await db.into(db.localRecords).insertOnConflictUpdate(LocalRecordsCompanion.insert(
      recordId: id, entity: entity, payload: jsonEncode(payload), syncStatus: const Value('pending'), updatedAt: now, deletedAt: Value(now)));
    await _queue(entity, id, 'delete', payload);
  }

  Future<void> _queue(String entity, String recordId, String operation, Map<String,dynamic> payload) async {
    await db.into(db.pendingOperations).insert(PendingOperationsCompanion.insert(
      id: const Uuid().v4(), entity: entity, recordId: recordId, operation: operation,
      payload: jsonEncode(payload), createdAt: DateTime.now().toUtc()));
  }

  Future<void> syncEntity(String entity) async {
    final pending = await (db.select(db.pendingOperations)..where((t)=>t.entity.equals(entity))).get();
    for (final op in pending) {
      try {
        final data = Map<String,dynamic>.from(jsonDecode(op.payload));
        if (op.operation == 'delete') {
          await supabase.from(entity).update({'deleted_at': data['deleted_at'], 'updated_at': data['updated_at']}).eq('id', op.recordId);
        } else {
          await supabase.from(entity).upsert(data);
        }
        await (db.delete(db.pendingOperations)..where((t)=>t.id.equals(op.id))).go();
        await (db.update(db.localRecords)..where((t)=>t.entity.equals(entity) & t.recordId.equals(op.recordId))).write(const LocalRecordsCompanion(syncStatus: Value('synced'), syncError: Value(null)));
      } catch (e) {
        await (db.update(db.pendingOperations)..where((t)=>t.id.equals(op.id))).write(PendingOperationsCompanion(attempts: Value(op.attempts+1), lastError: Value(e.toString())));
        await (db.update(db.localRecords)..where((t)=>t.entity.equals(entity) & t.recordId.equals(op.recordId))).write(LocalRecordsCompanion(syncStatus: const Value('error'), syncError: Value(e.toString())));
      }
    }
    final remote = await supabase.from(entity).select().order('updated_at');
    for (final raw in remote) {
      final row = Map<String,dynamic>.from(raw);
      final updated = DateTime.tryParse(row['updated_at']?.toString() ?? '') ?? DateTime.now().toUtc();
      final deleted = DateTime.tryParse(row['deleted_at']?.toString() ?? '');
      await db.into(db.localRecords).insertOnConflictUpdate(LocalRecordsCompanion.insert(
        recordId: row['id'].toString(), entity: entity, payload: jsonEncode(row), syncStatus: const Value('synced'), updatedAt: updated, deletedAt: Value(deleted)));
    }
  }
}
