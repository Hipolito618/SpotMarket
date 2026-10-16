import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Botones comunes de la barra superior: cambio de tema y cierre de sesión.
List<Widget> accionesSesion(BuildContext context) {
  final esOscuro = Theme.of(context).brightness == Brightness.dark;
  return [
    IconButton(
      tooltip: 'Cambiar tema',
      icon: Icon(esOscuro ? Icons.light_mode : Icons.dark_mode),
      onPressed: () => AdaptiveTheme.of(context).toggleThemeMode(),
    ),
    IconButton(
      tooltip: 'Cerrar sesión',
      icon: const Icon(Icons.logout),
      onPressed: AuthService.instancia.cerrarSesion,
    ),
  ];
}