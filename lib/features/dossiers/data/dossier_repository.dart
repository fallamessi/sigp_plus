import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/local_database.dart';
import '../../../core/network/entity_repository.dart';
import '../domain/dossier.dart';

class DossierRepository {
  DossierRepository(this._supabase, this._local)
      : _offline = EntityRepository(_supabase, _local);

  final SupabaseClient _supabase;
  final LocalDatabase _local;
  final EntityRepository _offline;

  Future<List<Dossier>> list({
    String search = '',
    String status = '',
  }) async {
    try {
      dynamic query = _supabase.from('dossiers').select('''
        id,
        numero_dossier,
        statut_courant,
        created_at,
        deleted_at,
        types_dossier(categorie, type),
        services(nom),
        dossier_personne(
          role,
          personnes(nom, prenom)
        )
      ''').isFilter('deleted_at', null);

      if (status.trim().isNotEmpty && status != 'Tous') {
        query = query.eq('statut_courant', status.trim());
      }

      final response = await query.order('created_at', ascending: false).limit(200);
      final rows = (response as List)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

      await _local.cacheMany('dossiers', rows);
      return _filterAndMap(rows, search);
    } catch (_) {
      final cached = await _offline.list('dossiers', search: search);
      return _filterAndMap(cached, search);
    }
  }

  List<Dossier> _filterAndMap(
    List<Map<String, dynamic>> rows,
    String search,
  ) {
    final needle = search.trim().toLowerCase();
    return rows
        .map(Dossier.fromJson)
        .where((dossier) {
          if (needle.isEmpty) return true;
          return dossier.numero.toLowerCase().contains(needle) ||
              dossier.assure.toLowerCase().contains(needle) ||
              dossier.typeDossier.toLowerCase().contains(needle) ||
              dossier.statut.toLowerCase().contains(needle);
        })
        .toList();
  }

  Future<void> delete(String id) async {
    final deletedAt = DateTime.now().toUtc().toIso8601String();
    await _offline.update('dossiers', id, {
      'deleted_at': deletedAt,
      'updated_at': deletedAt,
    });
  }
}
