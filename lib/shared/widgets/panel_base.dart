import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/perfil.dart';
import '../services/auth_service.dart';

/// Estructura común de las pantallas de inicio de cada rol.
class PanelBase extends StatelessWidget {
  const PanelBase({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.icono,
  });

  final String titulo;
  final String descripcion;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instancia;
    final perfil = auth.perfil;
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          IconButton(
            tooltip: 'Cambiar tema',
            icon: Icon(esOscuro ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => AdaptiveTheme.of(context).toggleThemeMode(),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: auth.cerrarSesion,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                perfil?.nombre ?? 'Usuario',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text('Rol: ${auth.rol.etiqueta}'),
              const SizedBox(height: 12),
              Text(descripcion, textAlign: TextAlign.center),
              if (auth.rol != RolUsuario.administrador) ...[
                const SizedBox(height: 24),
                // Acceso de prueba para validar la protección de rutas por rol.
                // Se retira en la versión final.
                OutlinedButton(
                  onPressed: () => context.go('/admin'),
                  child: const Text('Probar acceso al panel de administración'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}