import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/controllers/theme_controller.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';

/// Instancia global de SupabaseClient accesible desde toda la aplicación
final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Supabase con URL y Clave Publicable
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // ignore: deprecated_member_use
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    debugPrint('Nota de inicialización de Supabase: $e');
  }

  runApp(const SpotMarketApp());
}

/// Widget raíz de la aplicación spotMarket.
/// Se suscribe de forma reactiva al [ThemeController] global mediante [ListenableBuilder],
/// garantizando que cualquier cambio entre Modo Claro y Modo Oscuro
/// se propague instantáneamente en todo el árbol de widgets sin parpadeos ni reconstrucciones innecesarias.
class SpotMarketApp extends StatelessWidget {
  const SpotMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'spotMarket',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.themeMode,
          home: const LoginScreen(),
        );
      },
    );
  }
}
