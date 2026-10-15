import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Temas claro y oscuro con tipografía unificada para toda la app.
class AppTheme {
  AppTheme._();

  static const Color _colorSemilla = Color(0xFF1E88E5);

  static ThemeData claro() => _construir(Brightness.light);

  static ThemeData oscuro() => _construir(Brightness.dark);

  static ThemeData _construir(Brightness brillo) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _colorSemilla,
        brightness: brillo,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
    );
  }
}