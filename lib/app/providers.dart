import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../features/auth/auth_service.dart';

final apiClientProvider = Provider((ref) => ApiClient());
final authServiceProvider =
    Provider((ref) => AuthService(ref.read(apiClientProvider)));
final authStateProvider = StateProvider<bool?>((ref) => null);
