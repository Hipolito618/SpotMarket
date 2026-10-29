/// Configuración central de credenciales y acceso a Supabase para spotMarket.
class SupabaseConfig {
  /// URL del proyecto Supabase.
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://iwdsqvigmcfsiyvjxspo.supabase.co',
  );

  /// Clave anónima pública / Publishable Key del proyecto Supabase.
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_oCvvXvNpU7pI0WH3jozA2g_Vf-57nZb',
  );

  /// Alias de clave publicable
  static const String publishableKey = anonKey;
}

