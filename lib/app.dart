import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/local_database.dart';
import 'core/offline_repository.dart';
import 'features/login_page.dart';
import 'features/shell_page.dart';

final dbProvider = Provider((ref) => LocalDatabase());
final repoProvider = Provider((ref) => OfflineRepository(ref.read(dbProvider), Supabase.instance.client));

class SigpApp extends StatelessWidget {
  const SigpApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'SIGP+',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6B4B), brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFF4F7F6),
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
      inputDecorationTheme: const InputDecorationTheme(filled: true, border: OutlineInputBorder()),
    ),
    home: Supabase.instance.client.auth.currentSession == null ? const LoginPage() : const ShellPage(),
  );
}
