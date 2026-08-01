import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../data/secure_session_store.dart';

final flutterSecureStorageProvider =
Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final sessionStoreProvider = Provider<SecureSessionStore>((ref) {
  return SecureSessionStore(
    ref.read(flutterSecureStorageProvider),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    ref.read(sessionStoreProvider),
  );
});