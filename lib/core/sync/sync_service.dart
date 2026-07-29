import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';

class SyncService {
  SyncService(this.db, this.api);

  final AppDatabase db;
  final ApiClient api;

  Future<void> start() async {
    Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        sync();
      }
    });
  }

  Future<void> enqueue(
    String entityName,
    String recordId,
    String operation,
    Map<String, dynamic> payload,
  ) async {
    final now = DateTime.now().toUtc();

    await db.into(db.syncQueue).insert(
          SyncQueueCompanion.insert(
            id: const Uuid().v4(),
            entityName: entityName,
            recordId: recordId,
            operation: operation,
            payload: Value(jsonEncode(payload)),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> sync() async {
    final pending = await db.select(db.syncQueue).get();

    if (pending.isNotEmpty) {
      await api.dio.post(
        '/sync/push',
        data: {
          'changes': pending
              .map(
                (item) => {
                  'table': item.entityName,
                  'record_id': item.recordId,
                  'operation': item.operation,
                  'payload': item.payload == null
                      ? <String, dynamic>{}
                      : jsonDecode(item.payload!),
                },
              )
              .toList(),
        },
      );

      await db.delete(db.syncQueue).go();
    }

    final lastSync = DateTime.fromMillisecondsSinceEpoch(0)
        .toUtc()
        .toIso8601String();

    final response = await api.dio.get(
      '/sync/pull',
      queryParameters: {'since': lastSync},
    );

    final responseBody = response.data as Map<String, dynamic>;
    final data = responseBody['data'] as Map<String, dynamic>? ?? {};

    for (final entry in data.entries) {
      final rows = entry.value as List<dynamic>;

      for (final rawRow in rows) {
        final row = Map<String, dynamic>.from(rawRow as Map);

        await db.into(db.localRecords).insertOnConflictUpdate(
              LocalRecordsCompanion.insert(
                id: row['id'].toString(),
                entityName: entry.key,
                payload: jsonEncode(row),
                syncStatus: const Value('synced'),
                localUpdatedAt: DateTime.now().toUtc(),
                serverUpdatedAt: Value(
                  DateTime.tryParse(row['updated_at']?.toString() ?? ''),
                ),
                deletedAt: Value(
                  DateTime.tryParse(row['deleted_at']?.toString() ?? ''),
                ),
              ),
            );
      }
    }
  }
}
