import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/network/api_client.dart';

class AuthService {
  AuthService(
    this._apiClient, {
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _profileKey = 'profile';

  Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw const ApiException(
        'L’adresse e-mail et le mot de passe sont obligatoires.',
      );
    }

    final response = await _apiClient.request(
      '/auth/login',
      method: 'POST',
      body: <String, dynamic>{
        'email': normalizedEmail,
        'password': password,
      },
    );

    final rawData = response['data'];
    if (rawData is! Map) {
      throw const ApiException(
        'La réponse de connexion du serveur est incomplète.',
      );
    }

    final data = Map<String, dynamic>.from(rawData);
    final accessToken = data['access_token']?.toString() ?? '';
    final refreshToken = data['refresh_token']?.toString() ?? '';
    final rawProfile = data['profile'];

    if (accessToken.isEmpty) {
      throw const ApiException(
        'Le serveur n’a retourné aucun jeton d’accès.',
      );
    }

    await _storage.write(
      key: _accessTokenKey,
      value: accessToken,
    );

    if (refreshToken.isNotEmpty) {
      await _storage.write(
        key: _refreshTokenKey,
        value: refreshToken,
      );
    } else {
      await _storage.delete(key: _refreshTokenKey);
    }

    if (rawProfile is Map) {
      await _storage.write(
        key: _profileKey,
        value: jsonEncode(Map<String, dynamic>.from(rawProfile)),
      );
    } else {
      await _storage.delete(key: _profileKey);
    }

    return data;
  }

  Future<bool> hasSession() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    return accessToken != null && accessToken.trim().isNotEmpty;
  }

  Future<String?> accessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> refreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<Map<String, dynamic>?> profile() async {
    final storedProfile = await _storage.read(key: _profileKey);

    if (storedProfile == null || storedProfile.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(storedProfile);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } on FormatException {
      await _storage.delete(key: _profileKey);
      return null;
    }
  }

  Future<void> logout() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _profileKey),
    ]);
  }
}
