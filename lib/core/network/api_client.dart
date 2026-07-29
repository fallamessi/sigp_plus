import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  final _storage = const FlutterSecureStorage();
  Future<Map<String, dynamic>> request(String path,
      {String method = 'GET', Map<String, dynamic>? body}) async {
    final token = await _storage.read(key: 'access_token');
    final r = await _client
        .send(http.Request(method, Uri.parse('${AppConfig.apiBaseUrl}$path'))
          ..headers.addAll({
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token'
          })
          ..body = body == null ? '' : jsonEncode(body))
        .timeout(const Duration(seconds: 30));
    final resp = await http.Response.fromStream(r);
    Map<String, dynamic> json;
    try {
      json = jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Réponse serveur invalide.',
          statusCode: resp.statusCode);
    }
    if (resp.statusCode < 200 ||
        resp.statusCode >= 300 ||
        json['success'] != true)
      throw ApiException(json['message']?.toString() ?? 'Erreur serveur.',
          statusCode: resp.statusCode);
    return json;
  }
}
