import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
      (ref) {
    throw StateError(
      'supabaseClientProvider doit être remplacé dans main.dart.',
    );
  },
);