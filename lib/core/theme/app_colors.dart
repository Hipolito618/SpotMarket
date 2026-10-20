import 'package:flutter/material.dart';

abstract class AppColors {
  // --- MODO CLARO ---
  static const Color lightScaffold = Color(0xFFF6F4F0); // Crema / cantera cálida
  static const Color lightSurface = Color(0xFFFFFFFF); // Blanco puro
  static const Color lightPrimary = Color(0xFFF05A24); // Mandarina cempasúchil
  static const Color lightSecondary = Color(0xFFD81B60); // Rosa bugambilia
  static const Color lightTertiary = Color(0xFF1B7F4B); // Verde nopal
  static const Color lightTextPrimary = Color(0xFF202124); // Carbón asfalto
  static const Color lightTextSecondary = Color(0xFF5F6368); // Gris medio
  static const Color lightInputBackground = Color(0xFFEDE9E3); // Contenedores suaves
  static const Color lightBorder = Color(0xFFE0DCD5);

  // --- MODO OSCURO ---
  static const Color darkScaffold = Color(0xFF141311); // Carbón mineral cálido
  static const Color darkSurface = Color(0xFF22201D); // Barro ahumado
  static const Color darkInputBackground = Color(0xFF2D2A26); // Inputs / Contenedores
  static const Color darkPrimary = Color(0xFFFF7740); // Mandarina neón cálido
  static const Color darkSecondary = Color(0xFFFF5288); // Rosa bugambilia brillante
  static const Color darkTertiary = Color(0xFF3DD598); // Verde esmeralda fresco
  static const Color darkTextPrimary = Color(0xFFF5F2EB); // Marfil suave
  static const Color darkTextSecondary = Color(0xFFA8A39A); // Marfil tenue
  static const Color darkBorder = Color(0xFF3A3631);
}
