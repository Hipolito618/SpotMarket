import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Restaura la sesión y el perfil (con respaldo local) antes de montar la app.
  await AuthService.instancia.iniciar();
  final temaGuardado = await AdaptiveTheme.getThemeMode();

  runApp(SpotMarketApp(temaInicial: temaGuardado));
}