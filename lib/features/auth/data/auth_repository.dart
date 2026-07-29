import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/app_user.dart';
import '../../../core/network/api_client.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;
  final ApiClient api;
  AuthRepository(this.api);
  Future<AppUser> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
    final r = await api.dio.get('/auth/me');
    return AppUser.fromJson(Map<String, dynamic>.from(r.data['data']));
  }

  Future<void> signOut() => _supabase.auth.signOut();
}
