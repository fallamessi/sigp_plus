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
    final query = db.select(db.localRecords)
      ..where(
        (table) => table.entity.equals(entity) & table.deletedAt.isNull(),
      );

    return query.watch().map(
          (rows) => rows.map((record) {
            final payload = Map<String, dynamic>.from(
              jsonDecode(record.payload) as Map,
            );
            return {
              ...payload,
              '_sync_status': record.syncStatus,
              '_sync_error': record.syncError,
            };
          }).toList(),
        );
  }

  Future<void> save(
    String entity,
    Map<String, dynamic> values, {
    String? id,
  }) async {
    final recordId = id ?? const Uuid().v4();
    final now = DateTime.now().toUtc();
    final payload = <String, dynamic>{
      ...values,
      'id': recordId,
      'updated_at': now.toIso8601String(),
      'deleted_at': null,
    };

    await db.into(db.localRecords).insertOnConflictUpdate(
          LocalRecordsCompanion.insert(
            recordId: recordId,
            entity: entity,
            payload: jsonEncode(payload),
            syncStatus: const Value('pending'),
            updatedAt: now,
          ),
        );

    await _queue(entity, recordId, 'upsert', payload);
  }

  Future<void> remove(
    String entity,
    Map<String, dynamic> item,
  ) async {
    final id = item['id']?.toString();
    if (id == null || id.isEmpty) {
      throw ArgumentError('Identifiant absent : suppression impossible.');
    }

    final now = DateTime.now().toUtc();
    final payload = <String, dynamic>{
      ...item,
      'deleted_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    await db.into(db.localRecords).insertOnConflictUpdate(
          LocalRecordsCompanion.insert(
            recordId: id,
            entity: entity,
            payload: jsonEncode(payload),
            syncStatus: const Value('pending'),
            updatedAt: now,
            deletedAt: Value(now),
          ),
        );

    await _queue(entity, id, 'delete', payload);
  }

  Future<void> _queue(
    String entity,
    String recordId,
    String operation,
    Map<String, dynamic> payload,
  ) async {
    await db.into(db.pendingOperations).insert(
          PendingOperationsCompanion.insert(
            id: const Uuid().v4(),
            entity: entity,
            recordId: recordId,
            operation: operation,
            payload: jsonEncode(payload),
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<void> syncEntity(String entity) async {
    final pending = await (db.select(db.pendingOperations)
          ..where((table) => table.entity.equals(entity)))
        .get();

    for (final operation in pending) {
      try {
        final data = Map<String, dynamic>.from(
          jsonDecode(operation.payload) as Map,
        );

        if (operation.operation == 'delete') {
          await supabase.from(entity).update({
            'deleted_at': data['deleted_at'],
            'updated_at': data['updated_at'],
          }).eq('id', operation.recordId);
        } else {
          await supabase.from(entity).upsert(data);
        }

        await (db.delete(db.pendingOperations)
              ..where((table) => table.id.equals(operation.id)))
            .go();

        await (db.update(db.localRecords)
              ..where(
                (table) =>
                    table.entity.equals(entity) &
                    table.recordId.equals(operation.recordId),
              ))
            .write(
          const LocalRecordsCompanion(
            syncStatus: Value('synced'),
            syncError: Value(null),
          ),
        );
      } catch (error) {
        await (db.update(db.pendingOperations)
              ..where((table) => table.id.equals(operation.id)))
            .write(
          PendingOperationsCompanion(
            attempts: Value(operation.attempts + 1),
            lastError: Value(error.toString()),
          ),
        );

        await (db.update(db.localRecords)
              ..where(
                (table) =>
                    table.entity.equals(entity) &
                    table.recordId.equals(operation.recordId),
              ))
            .write(
          LocalRecordsCompanion(
            syncStatus: const Value('error'),
            syncError: Value(error.toString()),
          ),
        );
      }
    }

    final remoteRows = await supabase.from(entity).select().order('updated_at');

    for (final raw in remoteRows) {
      final row = Map<String, dynamic>.from(raw);
      final id = row['id']?.toString();
      if (id == null || id.isEmpty) continue;

      final updated = DateTime.tryParse(row['updated_at']?.toString() ?? '') ??
          DateTime.now().toUtc();
      final deleted = DateTime.tryParse(row['deleted_at']?.toString() ?? '');

      await db.into(db.localRecords).insertOnConflictUpdate(
            LocalRecordsCompanion.insert(
              recordId: id,
              entity: entity,
              payload: jsonEncode(row),
              syncStatus: const Value('synced'),
              updatedAt: updated,
              deletedAt: Value(deleted),
            ),
          );
    }
  }
}
