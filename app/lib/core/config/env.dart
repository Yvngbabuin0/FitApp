/// Configuración de la app.
///
/// ⚠️ VALORES PROVISIONALES: sustituir por los reales del proyecto Supabase
/// (Settings → API) cuando esté creado.
///  - La `anon key` es **pública por diseño** (la seguridad real la da RLS).
///  - La clave `service_role` NUNCA debe ir aquí.
class Env {
  Env._();

  static const String supabaseUrl = 'https://ajxzmkskdzlbrcghbquz.supabase.co';

  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFqeHpta3NrZHpsYnJjZ2hicXV6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE1MDQ3MjQsImV4cCI6MjEwNzA4MDcyNH0.s9H9Bj6ykVUcAtTD84BfmBvWseg8GcACNMX4_aBlggc';

  /// Ruta de la función de análisis de comidas.
  static const String analyzeMealPath = 'analyze-meal';
}