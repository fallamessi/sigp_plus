import 'api_client.dart';

class EntityRepository {
  EntityRepository(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list(String entity, {String search = ''}) async {
    final response = await _api.get('/api/entities/$entity', query: {'search': search, 'limit': '100'});
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    return ((data['items'] as List?) ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  Future<Map<String, dynamic>> create(String entity, Map<String, dynamic> data) async => Map<String, dynamic>.from((await _api.post('/api/entities/$entity', body: data))['data'] as Map);
  Future<Map<String, dynamic>> update(String entity, String id, Map<String, dynamic> data) async => Map<String, dynamic>.from((await _api.patch('/api/entities/$entity/$id', body: data))['data'] as Map);
  Future<void> delete(String entity, String id) async { await _api.delete('/api/entities/$entity/$id'); }
}
