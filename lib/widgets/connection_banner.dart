import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/connectivity_service.dart';
import '../services/pending_queue.dart';

/// Envuelve la app y muestra una franja superior cuando no hay conexión
/// o existen publicaciones pendientes de sincronizar.
class ConnectionBanner extends StatefulWidget {
  const ConnectionBanner({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends State<ConnectionBanner> {
  bool _verificando = false;

  /// Vuelve a comprobar la red y, si hay conexión, envía las publicaciones pendientes.
  Future<void> _reintentar() async {
    setState(() => _verificando = true);
    final enLinea = await ConnectivityService.instance.verificar();
    if (enLinea) await PendingQueue.instance.sincronizar();
    if (mounted) setState(() => _verificando = false);
  }

  String _mensaje(bool sinConexion, bool sincronizando, int pendientes) {
    if (sinConexion) {
      return pendientes > 0
          ? 'Sin conexión · modo offline · $pendientes por enviar'
          : 'Sin conexión · modo offline';
    }
    if (sincronizando) return 'Sincronizando $pendientes publicación(es)...';
    return '$pendientes publicación(es) pendiente(s) de enviar';
  }

  Widget _franja({
    required bool sinConexion,
    required bool sincronizando,
    required int pendientes,
  }) {
    final fondo =
    sinConexion ? const Color(0xFF3A3631) : const Color(0xFFF05A24);

    return Material(
      color: fondo,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              if (sincronizando)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(
                  sinConexion ? Icons.cloud_off_rounded : Icons.sync_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _mensaje(sinConexion, sincronizando, pendientes),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!sincronizando)
                TextButton(
                  onPressed: _verificando ? null : _reintentar,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 30),
                  ),
                  child: Text(
                    _verificando ? 'Verificando...' : 'Reintentar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conectividad = ConnectivityService.instance;
    final cola = PendingQueue.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([conectividad.isOnline, cola]),
      builder: (context, _) {
        final sinConexion = !conectividad.isOnline.value;
        final pendientes = cola.cantidad;
        final visible = sinConexion || pendientes > 0;
        final sincronizando = !sinConexion && cola.sincronizando;

        // La franja ocupa siempre la primera posición para que el árbol de
        // navegación conserve su estado al mostrarse u ocultarse.
        return Column(
          children: [
            visible
                ? _franja(
              sinConexion: sinConexion,
              sincronizando: sincronizando,
              pendientes: pendientes,
            )
                : const SizedBox.shrink(),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: visible,
                child: widget.child,
              ),
            ),
          ],
        );
      },
    );
  }
}