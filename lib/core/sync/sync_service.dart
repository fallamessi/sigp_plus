import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../database/local_database.dart';
import '../network/api_client.dart';

class SyncService {
  SyncService(this._api, {LocalDatabase? database}) : _db = database ?? LocalDatabase.instance;
  final ApiClient _api;
  final LocalDatabase _db;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _running = false;

  void start() {
    _subscription ??= Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) syncNow();
    });
  }

  Future<void> syncNow() async {
    if (_running) return;
    _running = true;
    try {
      final operations = await _db.pendingOperations();
      for (final op in operations) {
        final queueId = op['id']! as int;
        final entity = op['entity']! as String;
        final recordId = op['record_id']! as String;
        final operation = op['operation']! as String;
        final payloadText = op['payload'] as String?;
        final payload = payloadText == null ? <String, dynamic>{} : Map<String, dynamic>.from(jsonDecode(payloadText) as Map);
        try {
          Map<String, dynamic>? saved;
          if (operation == 'create') {
            saved = Map<String, dynamic>.from((await _api.post('/api/entities/$entity', body: payload))['data'] as Map);
          } else if (operation == 'update') {
            saved = Map<String, dynamic>.from((await _api.patch('/api/entities/$entity/$recordId', body: payload))['data'] as Map);
          } else {
            await _api.delete('/api/entities/$entity/$recordId');
          }
          if (saved != null) await _db.cacheMany(entity, [saved]);
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
