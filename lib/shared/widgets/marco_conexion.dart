import 'package:flutter/material.dart';

import '../services/cola_pendientes.dart';
import '../services/conectividad_service.dart';

/// Envuelve toda la app y muestra una franja superior cuando no hay
/// conexión o hay cambios pendientes de sincronizar.
class MarcoConexion extends StatelessWidget {
  const MarcoConexion({super.key, required this.child});

  final Widget child;

  String? _mensaje(bool sinRed, int pendientes) {
    if (sinRed) {
      return pendientes > 0
          ? 'Sin conexión · modo offline · $pendientes por sincronizar'
          : 'Sin conexión · modo offline';
    }
    if (pendientes > 0) return 'Sincronizando $pendientes cambio(s)…';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final conectividad = ConectividadService.instancia;
    final cola = ColaPendientes.instancia;

    return ListenableBuilder(
      listenable: Listenable.merge([conectividad.enLinea, cola]),
      builder: (context, _) {
        final sinRed = !conectividad.enLinea.value;
        final mensaje = _mensaje(sinRed, cola.cantidad);
        final esquema = Theme.of(context).colorScheme;
        final colorTexto =
        sinRed ? esquema.onErrorContainer : esquema.onTertiaryContainer;

        return Column(
          children: [
            // La posición del hijo en la columna es fija para conservar su estado.
            mensaje == null
                ? const SizedBox.shrink()
                : Material(
              color: sinRed
                  ? esquema.errorContainer
                  : esquema.tertiaryContainer,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.paddingOf(context).top + 6,
                  16,
                  6,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(sinRed ? Icons.cloud_off : Icons.sync,
                        size: 16, color: colorTexto),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        mensaje,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: colorTexto),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: mensaje != null,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}