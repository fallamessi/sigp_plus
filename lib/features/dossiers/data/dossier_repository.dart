import '../../../core/network/api_client.dart';
import '../domain/dossier.dart';

class DossierRepository {
  const DossierRepository(this._api);
  final ApiClient _api;

  Future<List<Dossier>> list({String search = '', String status = ''}) async {
    final response = await _api.get('/api/dossiers', query: {
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (status.trim().isNotEmpty && status != 'Tous') 'statut': status,
      'limit': '100',
    });
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    final items = data['items'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(Dossier.fromJson)
        .toList();
  }

  Future<void> delete(String id) async {
    await _api.delete('/api/dossiers/$id');
  }
}
