import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../data/secure_session_store.dart';
import '../domain/app_user.dart';

const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

final secureSessionStoreProvider = Provider<SecureSessionStore>(
  (ref) => const SecureSessionStore(_secureStorage),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(secureSessionStoreProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(secureSessionStoreProvider),
    ref.watch(apiClientProvider),
  ),
);

class AuthState {
  const AuthState({this.user, this.loading = false, this.error});
  final AppUser? user;
  final bool loading;
  final String? error;
  bool get authenticated => user != null;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState());
  final AuthRepository _repository;

  Future<bool> login(String email, String password) async {
    state = const AuthState(loading: true);
    try {
      final user = await _repository.login(email, password);
      state = AuthState(user: user);
      return true;
    } on AuthException catch (error) {
      state = AuthState(error: error.message);
      return false;
    } catch (_) {
      state = const AuthState(error: 'Une erreur inattendue est survenue.');
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.watch(authRepositoryProvider)),
);
