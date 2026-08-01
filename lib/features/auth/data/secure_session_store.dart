import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStore {
  const SecureSessionStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'sigp_access_token';
  static const _refreshTokenKey = 'sigp_refresh_token';
  static const _userEmailKey = 'sigp_user_email';

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required String email,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _userEmailKey, value: email),
    ]);
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<String?> readEmail() => _storage.read(key: _userEmailKey);

  Future<void> clear() => _storage.deleteAll();
}
