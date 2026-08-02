class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String ocrServiceUrl = String.fromEnvironment(
    'OCR_SERVICE_URL',
    defaultValue: '',
  );

  static const String aiServiceUrl = String.fromEnvironment(
    'AI_SERVICE_URL',
    defaultValue: '',
  );

  static bool get hasSupabaseConfiguration {
    return supabaseUrl.trim().isNotEmpty &&
        supabaseAnonKey.trim().isNotEmpty;
  }

  static void validate() {
    if (supabaseUrl.trim().isEmpty) {
      throw StateError(
        'SUPABASE_URL est absent.\n'
            'Lancez l’application avec :\n'
            '--dart-define=SUPABASE_URL=https://ycfwmtfbnovznaoggjrl.supabase.co',
      );
    }

    if (supabaseAnonKey.trim().isEmpty) {
      throw StateError(
        'SUPABASE_ANON_KEY est absent.\n'
            'Lancez l’application avec :\n'
            '--dart-define=SUPABASE_ANON_KEY=sb_publishable_0ODk2dpWYwfVY-8FYQ33KQ_-DFfukeJ',
      );
    }

    final uri = Uri.tryParse(supabaseUrl);

    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        uri.scheme != 'https') {
      throw StateError(
        'SUPABASE_URL est invalide : $supabaseUrl',
      );
    }
  }
}