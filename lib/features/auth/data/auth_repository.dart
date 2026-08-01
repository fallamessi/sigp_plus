import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/app_user.dart';
import 'secure_session_store.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository(this._store, this._apiClient);

  final SecureSessionStore _store;
  final ApiClient _apiClient;

  Future<AppUser> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/api/auth/login',
        authenticated: false,
        body: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );
      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) throw const AuthException('Réponse de connexion invalide.');

      final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      await _store.save(
        accessToken: data['access_token']?.toString() ?? '',
        refreshToken: data['refresh_token']?.toString() ?? '',
        email: user.email,
      );
      return user;
    } on ApiException catch (error) {
      throw AuthException(error.message);
    }
  }

  Future<void> logout() => _store.clear();
}
