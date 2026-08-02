import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../database/local_database.dart';

class EntityRepository {
  static const Set<String> allowedEntities = <String>{
    'agences',
    'services',
    'roles',
    'permissions',
    'role_permissions',
    'profils_utilisateurs',
    'types_dossier',
    'categories_document',
    'pieces_requises',
    'personnes',
    'dossiers',
    'dossier_personne',
    'dossier_pieces_checklist',
    'modeles_documents',
    'traitements_liquidation',
    'workflow_etapes_ref',
    'workflow_instances',
    'workflow_historique',
    'workflow_transitions',
    'workflow_etape_statut_map',
    'documents',
    'documents_generes',
    'ia_analyses',
    'chatbot_conversations',
    'chatbot_messages',
    'categories_motif_rejet',
    'regles_controle',
    'rejets',
    'imports_titres',
    'import_titre_details',
    'etablissements_bancaires',
    'engagements_irrevocables',
    'archives',
    'notifications',
    'audit_log',
  };

  static void validateEntity(String entity) {
    if (!allowedEntities.contains(entity)) {
      throw ArgumentError.value(entity, 'entity', 'Table Supabase non autorisée');
    }
  }

  EntityRepository(this._supabase, this._local);

  final SupabaseClient _supabase;
  final LocalDatabase _local;

  Future<List<Map<String, dynamic>>> list(String entity, {String search = ''}) async {
    validateEntity(entity);
    final cached = await _local.readEntity(entity, search: search);
    try {
      final remote = await _supabase.from(entity).select().limit(500);
      final rows = remote.map((e) => Map<String, dynamic>.from(e)).toList();
      await _local.cacheMany(entity, rows);
      return await _local.readEntity(entity, search: search);
    } catch (_) {
      return cached;
    }
  }

  Future<Map<String, dynamic>> create(String entity, Map<String, dynamic> data) async {
    validateEntity(entity);
    final now = DateTime.now().toUtc().toIso8601String();
    final item = <String, dynamic>{
      ...data,
      'id': data['id']?.toString().isNotEmpty == true ? data['id'] : const Uuid().v4(),
      'created_at': data['created_at'] ?? now,
      'updated_at': now,
    };
    await _local.upsertLocal(entity, item, operation: 'upsert');
    return item;
  }

  Future<Map<String, dynamic>> update(String entity, String id, Map<String, dynamic> data) async {
    validateEntity(entity);
    final item = <String, dynamic>{
      ...data,
      'id': id,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _local.upsertLocal(entity, item, operation: 'upsert');
    return item;
  }

  Future<void> delete(String entity, String id) {
    validateEntity(entity);
    return _local.markDeleted(entity, id);
  }
}
