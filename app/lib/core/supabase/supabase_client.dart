import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Inicializa el cliente de Supabase (url + anon key).
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );
}