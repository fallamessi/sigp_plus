import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_page.dart';
import '../features/dashboard/shell_page.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) => GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/app', builder: (_, __) => const ShellPage())
    ],
    redirect: (context, state) async {
      final ok = await ref.read(authServiceProvider).hasSession();
      if (!ok && state.matchedLocation != '/login') return '/login';
      if (ok && state.matchedLocation == '/login') return '/app';
      return null;
    }));
