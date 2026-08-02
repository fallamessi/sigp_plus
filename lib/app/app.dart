import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/supabase_provider.dart';
import '../core/sync/sync_service.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final service = SyncService(client)..start();
  ref.onDispose(service.dispose);
  return service;
});

class SigpApp extends ConsumerWidget {
  const SigpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncServiceProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SIGP+',
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
