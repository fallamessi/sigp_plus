import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../features/auth/data/secure_session_store.dart';
import '../constants/api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(
      this._sessionStore, [
        http.Client? client,
      ]) : _client = client ?? http.Client();

  final SecureSessionStore _sessionStore;
  final http.Client _client;

  Future<Map<String, dynamic>> get(
      String path, {
        Map<String, String>? query,
        bool authenticated = true,
      }) {
    return _send(
      'GET',
      _uri(path, query),
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> post(
      String path, {
        Map<String, dynamic>? body,
        bool authenticated = true,
      }) {
    return _send(
      'POST',
      _uri(path),
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> put(
      String path, {
        Map<String, dynamic>? body,
        bool authenticated = true,
      }) {
    return _send(
      'PUT',
      _uri(path),
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> patch(
      String path, {
        Map<String, dynamic>? body,
        bool authenticated = true,
      }) {
    return _send(
      'PATCH',
      _uri(path),
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> delete(
      String path, {
        Map<String, dynamic>? body,
        bool authenticated = true,
      }) {
    return _send(
      'DELETE',
      _uri(path),
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> _send(
      String method,
      Uri uri, {
        Map<String, dynamic>? body,
        required bool authenticated,
      }) async {
    final headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
    };

    String? token;

    if (authenticated) {
      token = await _sessionStore.readAccessToken();

      if (token == null ||
          token.trim().isEmpty ||
          token.trim().toLowerCase() == 'null') {
        throw const ApiException(
          'Aucune session valide n’a été trouvée. '
              'Veuillez vous reconnecter.',
          statusCode: 401,
        );
      }

      token = token.trim();

      headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }

    final encodedBody = body == null ? null : jsonEncode(body);

    developer.log(
      '=============================================',
      name: 'SIGP.API',
    );

    developer.log(
      'Requête HTTP : $method $uri',
      name: 'SIGP.API',
    );

    developer.log(
      'Authentification requise : $authenticated',
      name: 'SIGP.API',
    );

    developer.log(
      'Jeton présent : ${token != null && token.isNotEmpty}',
      name: 'SIGP.API',
    );

    developer.log(
      'Corps envoyé : ${_sanitizeBody(body)}',
      name: 'SIGP.API',
    );

    late final http.Response response;

    try {
      response = await _executeRequest(
        method: method,
        uri: uri,
        headers: headers,
        encodedBody: encodedBody,
      ).timeout(ApiConfig.timeout);
    } on TimeoutException catch (error, stackTrace) {
      developer.log(
        'Délai de réponse dépassé.',
        name: 'SIGP.API',
        error: error,
        stackTrace: stackTrace,
      );

      throw const ApiException(
        'Le serveur met trop de temps à répondre. '
            'Vérifiez votre connexion et réessayez.',
      );
    } on SocketException catch (error, stackTrace) {
      developer.log(
        'Serveur inaccessible.',
        name: 'SIGP.API',
        error: error,
        stackTrace: stackTrace,
      );

      throw const ApiException(
        'Impossible de joindre le serveur. '
            'Vérifiez votre connexion Internet ou assurez-vous '
            'que le serveur local est démarré.',
      );
    } on HttpException catch (error, stackTrace) {
      developer.log(
        'Erreur HTTP.',
        name: 'SIGP.API',
        error: error,
        stackTrace: stackTrace,
      );

      throw const ApiException(
        'Une erreur de communication avec le serveur est survenue.',
      );
    } on FormatException catch (error, stackTrace) {
      developer.log(
        'Format de données invalide.',
        name: 'SIGP.API',
        error: error,
        stackTrace: stackTrace,
      );

      throw const ApiException(
        'Les données envoyées ou reçues sont invalides.',
      );
    } on ApiException {
      rethrow;
    } catch (error, stackTrace) {
      developer.log(
        'Erreur inattendue pendant la requête.',
        name: 'SIGP.API',
        error: error,
        stackTrace: stackTrace,
      );

      throw ApiException(
        'Une erreur inattendue est survenue : $error',
      );
    }

    developer.log(
      'Code HTTP : ${response.statusCode}',
      name: 'SIGP.API',
    );

    developer.log(
      'Réponse brute : ${response.body}',
      name: 'SIGP.API',
    );

    final decoded = _decodeSafely(response.body);

    if (response.statusCode == 401) {
      await _sessionStore.clear();

      developer.log(
        'Session supprimée après une réponse HTTP 401.',
        name: 'SIGP.API',
      );

      developer.log(
        '=============================================',
        name: 'SIGP.API',
      );

      throw ApiException(
        decoded['message']?.toString().trim().isNotEmpty == true
            ? '${decoded['message']}\nVeuillez vous reconnecter.'
            : 'Votre session est invalide ou expirée. '
            'Veuillez vous reconnecter.',
        statusCode: 401,
        errors: _extractErrors(decoded),
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detailedMessage = _buildErrorMessage(
        decoded,
        response.statusCode,
      );

      developer.log(
        'Erreur API complète : $detailedMessage',
        name: 'SIGP.API',
      );

      developer.log(
        '=============================================',
        name: 'SIGP.API',
      );

      throw ApiException(
        detailedMessage,
        statusCode: response.statusCode,
        errors: _extractErrors(decoded),
      );
    }

    developer.log(
      'Requête réussie.',
      name: 'SIGP.API',
    );

    developer.log(
      '=============================================',
      name: 'SIGP.API',
    );

    return decoded;
  }

  Future<http.Response> _executeRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required String? encodedBody,
  }) {
    switch (method) {
      case 'POST':
        return _client.post(
          uri,
          headers: headers,
          body: encodedBody,
        );

      case 'PUT':
        return _client.put(
          uri,
          headers: headers,
          body: encodedBody,
        );

      case 'PATCH':
        return _client.patch(
          uri,
          headers: headers,
          body: encodedBody,
        );

      case 'DELETE':
        return _client.delete(
          uri,
          headers: headers,
          body: encodedBody,
        );

      case 'GET':
      default:
        return _client.get(
          uri,
          headers: headers,
        );
    }
  }

  Map<String, dynamic>? _extractErrors(
      Map<String, dynamic> decoded,
      ) {
    final errors = decoded['errors'];

    if (errors is Map<String, dynamic>) {
      return errors;
    }

    if (errors is Map) {
      return Map<String, dynamic>.from(errors);
    }

    return null;
  }

  String _buildErrorMessage(
      Map<String, dynamic> decoded,
      int statusCode,
      ) {
    final serverMessage = decoded['message']?.toString().trim();

    final message = serverMessage != null && serverMessage.isNotEmpty
        ? serverMessage
        : _defaultMessageForStatus(statusCode);

    final technicalError = decoded['error']?.toString().trim();
    final file = decoded['file']?.toString().trim();
    final line = decoded['line']?.toString().trim();

    final result = StringBuffer(message);

    if (technicalError != null &&
        technicalError.isNotEmpty &&
        technicalError.toLowerCase() != 'null') {
      result.write('\n\nErreur technique : $technicalError');
    }

    if (file != null &&
        file.isNotEmpty &&
        file.toLowerCase() != 'null') {
      result.write('\nFichier : $file');
    }

    if (line != null &&
        line.isNotEmpty &&
        line.toLowerCase() != 'null') {
      result.write('\nLigne : $line');
    }

    result.write('\nCode HTTP : $statusCode');

    return result.toString();
  }

  String _defaultMessageForStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Les informations envoyées sont invalides.';

      case 401:
        return 'Votre session est invalide ou expirée.';

      case 403:
        return 'Vous n’avez pas l’autorisation d’effectuer cette opération.';

      case 404:
        return 'La ressource demandée est introuvable.';

      case 409:
        return 'Cette donnée existe déjà ou provoque un conflit.';

      case 422:
        return 'Certains champs du formulaire sont invalides.';

      case 500:
        return 'Une erreur interne est survenue sur le serveur.';

      case 502:
      case 503:
      case 504:
        return 'Le serveur est temporairement indisponible.';

      default:
        return 'La requête a échoué.';
    }
  }

  Uri _uri(
      String path, [
        Map<String, String>? query,
      ]) {
    final normalized = path.startsWith('/') ? path : '/$path';

    return Uri.parse(
      '${ApiConfig.baseUrl}$normalized',
    ).replace(
      queryParameters: query == null || query.isEmpty ? null : query,
    );
  }

  Map<String, dynamic> _decodeSafely(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final value = jsonDecode(body);

      if (value is Map<String, dynamic>) {
        return value;
      }

      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }

      return <String, dynamic>{
        'message': 'Format de réponse inattendu.',
        'error': value.toString(),
      };
    } on FormatException catch (error, stackTrace) {
      developer.log(
        'Le serveur n’a pas retourné du JSON.',
        name: 'SIGP.API',
        error: error,
        stackTrace: stackTrace,
      );

      return <String, dynamic>{
        'message': 'Le serveur a retourné une réponse non JSON.',
        'error': body,
      };
    }
  }

  Map<String, dynamic>? _sanitizeBody(
      Map<String, dynamic>? body,
      ) {
    if (body == null) {
      return null;
    }

    final sanitized = Map<String, dynamic>.from(body);

    const sensitiveFields = <String>[
      'password',
      'password_confirmation',
      'mot_de_passe',
      'access_token',
      'refresh_token',
      'token',
    ];

    for (final field in sensitiveFields) {
      if (!sanitized.containsKey(field)) {
        continue;
      }

      final value = sanitized[field];

      sanitized[field] = value is String
          ? '[MASQUÉ - ${value.length} caractères]'
          : '[MASQUÉ]';
    }

    return sanitized;
  }

  void close() {
    _client.close();
  }
}