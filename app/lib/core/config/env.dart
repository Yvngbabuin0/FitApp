/// Configuración de la app.
///
/// ⚠️ VALORES PROVISIONALES: sustituir por los reales del proyecto Supabase
/// (Settings → API) cuando esté creado.
///  - La `anon key` es **pública por diseño** (la seguridad real la da RLS).
///  - La clave `service_role` NUNCA debe ir aquí.
class Env {
  Env._();

  static const String supabaseUrl = 'https://TU-PROYECTO.supabase.co';

  static const String supabaseAnonKey = 'PON_AQUI_TU_ANON_KEY';

  /// Ruta de la función de análisis de comidas.
  static const String analyzeMealPath = 'analyze-meal';
}