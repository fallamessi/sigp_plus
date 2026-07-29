import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';

class SigpApp extends ConsumerWidget {
  const SigpApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SIGP+',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B4D)),
          useMaterial3: true,
          inputDecorationTheme:
              const InputDecorationTheme(border: OutlineInputBorder())),
      routerConfig: ref.watch(routerProvider));
}
