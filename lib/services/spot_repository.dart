import 'package:flutter/foundation.dart';

import '../models/spot_item.dart';
import 'local_cache.dart';
import 'spot_service.dart';

/// Acceso a los spots con respaldo local.
///
/// Con conexión consulta Supabase y guarda el resultado en el dispositivo;
/// si la consulta falla, devuelve la última copia guardada.
class SpotRepository {
  SpotRepository._();

  static const Duration _tiempoMaximo = Duration(seconds: 12);

  /// Indica si la última consulta se resolvió con datos guardados en el dispositivo.
  static bool ultimaCargaDesdeCache = false;

  static Future<List<SpotItem>> obtenerSpotsActivos() async {
    try {
      final spots =
      await SpotService.obtenerSpotsActivos().timeout(_tiempoMaximo);
      if (SpotService.isSupabaseInitialized) {
        await LocalCache.guardarSpotsActivos(spots);
      }
      ultimaCargaDesdeCache = false;
      return spots;
    } catch (e) {
      debugPrint('Consulta de spots fallida, se intenta el caché: $e');
      final cache = await LocalCache.leerSpotsActivos();
      if (cache.isNotEmpty) {
        ultimaCargaDesdeCache = true;
        return cache;
      }
      rethrow;
    }
  }

  /// Elimina un spot del usuario autenticado junto con sus registros dependientes.
  static Future<void> eliminarSpot(dynamic claveSpot) async {
    if (!SpotService.isSupabaseInitialized ||
        SpotService.client.auth.currentUser == null) {
      throw Exception('Inicia sesión para eliminar publicaciones.');
    }
    final cliente = SpotService.client;

    // Se eliminan primero las tablas dependientes por si no hay borrado en cascada.
    for (final tabla in const ['foto_spot', 'comida', 'bazar', 'reventa']) {
      await cliente.from(tabla).delete().eq('clave_spot', claveSpot);
    }

    final eliminados = await cliente
        .from('spot')
        .delete()
        .eq('clave_spot', claveSpot)
        .eq('clave_usuario', cliente.auth.currentUser!.id)
        .select('clave_spot');

    if (eliminados.isEmpty) {
      throw Exception('La publicación no existe o no hay permiso para eliminarla.');
    }
  }
}