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
      }) async {
    final Uri uri = _uri(path, query);

    return _send(
      'GET',
      uri,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> post(
      String path, {
        Map<String, dynamic>? body,
        bool authenticated = true,
      }) async {
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
      }) async {
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
      }) async {
    return _send(
      'PATCH',
      _uri(path),
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> delete(
      String path, {
        bool authenticated = true,
      }) async {
    return _send(
      'DELETE',
      _uri(path),
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> _send(
      String method,
      Uri uri, {
        Map<String, dynamic>? body,
        required bool authenticated,
      }) async {
    final Map<String, String> headers = {
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader:
      'application/json; charset=utf-8',
    };

    if (authenticated) {
      final String? token =
      await _sessionStore.readAccessToken();

      if (token != null && token.isNotEmpty) {
        headers[HttpHeaders.authorizationHeader] =
        'Bearer $token';
      }
    }

    final String? encodedBody =
    body == null ? null : jsonEncode(body);

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
      'Corps envoyé : ${_sanitizeBody(body)}',
      name: 'SIGP.API',
    );

    late final http.Response response;

    try {
      response = switch (method) {
        'POST' => await _client
            .post(
          uri,
          headers: headers,
          body: encodedBody,
        )
            .timeout(ApiConfig.timeout),
        'PUT' => await _client
            .put(
          uri,
          headers: headers,
          body: encodedBody,
        )
            .timeout(ApiConfig.timeout),
        'PATCH' => await _client
            .patch(
          uri,
          headers: headers,
          body: encodedBody,
        )
            .timeout(ApiConfig.timeout),
        'DELETE' => await _client
            .delete(
          uri,
          headers: headers,
        )
            .timeout(ApiConfig.timeout),
        _ => await _client
            .get(
          uri,
          headers: headers,
        )
            .timeout(ApiConfig.timeout),
      };
    } on TimeoutException catch (error, stackTrace) {
      developer.log(
        'Délai de réponse dépassé.',
        name: 'SIGP.API',
        error: error,
        stackTrace: stackTrace,
      );

      throw const ApiException(
        'Le serveur met trop de temps à répondre.',
      );
    } on SocketException catch (error, stackTrace) {
      developer.log(
        'Serveur inaccessible.',
        name: 'SIGP.API',
        error: error,
        stackTrace: stackTrace,
      );

      throw const ApiException(
        'Serveur inaccessible. Vérifiez la connexion.',
      );
    } on HttpException catch (error, stackTrace) {
      developer.log(
        'Erreur HTTP.',
        name: 'SIGP.API',
        error: error,
        stackTrace: stackTrace,
      );

      throw const ApiException(
        'Erreur de communication avec le serveur.',
      );
    } on FormatException catch (error, stackTrace) {
      developer.log(
        'Format de réponse invalide.',
        name: 'SIGP.API',
        error: error,
        stackTrace: stackTrace,
      );

      throw const ApiException(
        'Réponse invalide du serveur.',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Erreur inattendue pendant la requête.',
        name: 'SIGP.API',
        error: error,
        stackTrace: stackTrace,
      );

      throw ApiException(
        'Erreur inattendue : $error',
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

    final Map<String, dynamic> decoded =
    _decodeSafely(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      final String detailedMessage =
      _buildErrorMessage(
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
        errors: decoded['errors']
        is Map<String, dynamic>
            ? decoded['errors']
        as Map<String, dynamic>
            : null,
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

  String _buildErrorMessage(
      Map<String, dynamic> decoded,
      int statusCode,
      ) {
    final String message =
    decoded['message']
        ?.toString()
        .trim()
        .isNotEmpty ==
        true
        ? decoded['message']
        .toString()
        .trim()
        : 'Erreur serveur.';

    final String? technicalError =
    decoded['error']?.toString().trim();

    final String? file =
    decoded['file']?.toString().trim();

    final String? line =
    decoded['line']?.toString().trim();

    final StringBuffer result =
    StringBuffer(message);

    if (technicalError != null &&
        technicalError.isNotEmpty &&
        technicalError.toLowerCase() != 'null') {
      result.write(
        '\n\nErreur technique : $technicalError',
      );
    }

    if (file != null &&
        file.isNotEmpty &&
        file.toLowerCase() != 'null') {
      result.write(
        '\nFichier : $file',
      );
    }

    if (line != null &&
        line.isNotEmpty &&
        line.toLowerCase() != 'null') {
      result.write(
        '\nLigne : $line',
      );
    }

    result.write(
      '\nCode HTTP : $statusCode',
    );

    return result.toString();
  }

  Uri _uri(
      String path, [
        Map<String, String>? query,
      ]) {
    final String normalized =
    path.startsWith('/')
        ? path
        : '/$path';

    return Uri.parse(
      '${ApiConfig.baseUrl}$normalized',
    ).replace(
      queryParameters:
      query?.isEmpty == true ? null : query,
    );
  }

  Map<String, dynamic> _decodeSafely(
      String body,
      ) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final dynamic value = jsonDecode(body);

      if (value is Map<String, dynamic>) {
        return value;
      }

      if (value is Map) {
        return Map<String, dynamic>.from(
          value,
        );
      }

      return <String, dynamic>{
        'message':
        'Format de réponse inattendu.',
        'error': value.toString(),
      };
    } on FormatException catch (
    error,
    stackTrace
    ) {
    developer.log(
    'Le serveur n’a pas retourné du JSON.',
    name: 'SIGP.API',
    error: error,
    stackTrace: stackTrace,
    );

    return <String, dynamic>{
    'message':
    'Le serveur a retourné une réponse non JSON.',
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

    final Map<String, dynamic> sanitized =
    Map<String, dynamic>.from(body);

    const List<String> sensitiveFields = [
      'password',
      'mot_de_passe',
      'access_token',
      'refresh_token',
      'token',
    ];

    for (final String field
    in sensitiveFields) {
      if (sanitized.containsKey(field)) {
        final dynamic value =
        sanitized[field];

        sanitized[field] =
        value is String
            ? '[MASQUÉ - ${value.length} caractères]'
            : '[MASQUÉ]';
      }
    }

    return sanitized;
  }
}