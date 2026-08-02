import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/local_database.dart';
import '../network/entity_repository.dart';

class SyncService {
  SyncService(this._supabase, {LocalDatabase? database})
      : _db = database ?? LocalDatabase.instance;

  final SupabaseClient _supabase;
  final LocalDatabase _db;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _running = false;

  void start() {
    _subscription ??= Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) syncNow();
    });
    syncNow();
  }

  Future<void> syncNow() async {
    if (_running || _supabase.auth.currentSession == null) return;
    _running = true;
    try {
      final operations = await _db.pendingOperations();
      for (final op in operations) {
        final queueId = op['id']! as int;
        final entity = op['entity']! as String;
        EntityRepository.validateEntity(entity);
        final recordId = op['record_id']! as String;
        final operation = op['operation']! as String;
        final payloadText = op['payload'] as String?;
        try {
          if (operation == 'delete') {
            await _supabase.from(entity).delete().eq('id', recordId);
          } else {
            final payload = Map<String, dynamic>.from(
              jsonDecode(payloadText ?? '{}') as Map,
            );
            await _supabase.from(entity).upsert(payload, onConflict: 'id');
          }
          await _db.removeOperation(queueId);
        } catch (error) {
          await _db.markOperationFailed(queueId, error);
          break;
        }
      }
    } finally {
      _running = false;
    }
  }

  Future<void> dispose() async => _subscription?.cancel();
}
