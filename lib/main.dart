import 'package:flutter/material.dart';
import 'core/controllers/theme_controller.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
