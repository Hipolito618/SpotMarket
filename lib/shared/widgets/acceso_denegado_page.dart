import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pantalla mostrada cuando el rol no tiene permiso para la ruta solicitada.
class AccesoDenegadoPage extends StatelessWidget {
  const AccesoDenegadoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline,
                  size: 72, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Acceso denegado',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'No tienes permiso para ver esta sección.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Volver a mi inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}