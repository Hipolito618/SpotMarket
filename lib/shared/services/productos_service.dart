import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/producto.dart';
import 'cache_local.dart';
import 'cola_pendientes.dart';

/// Error con mensaje listo para mostrar al usuario.
class ServicioFallo implements Exception {
  const ServicioFallo(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Lista de productos y su origen (servidor o caché local).
class ResultadoProductos {
  const ResultadoProductos(this.productos, {required this.desdeCache});

  final List<Producto> productos;
  final bool desdeCache;
}

/// Acceso a productos y favoritos. Lee del servidor y recurre al caché
/// local cuando no hay conexión; las escrituras pasan por la cola de pendientes.
class ProductosService {
  ProductosService._();

  static final ProductosService instancia = ProductosService._();

  static const Duration _tiempoMaximo = Duration(seconds: 10);

  SupabaseClient get _cliente => Supabase.instance.client;
  String? get _usuarioId => _cliente.auth.currentUser?.id;

  /// Publicaciones activas visibles para todos los usuarios.
  Future<ResultadoProductos> obtenerCatalogo() async {
    await ColaPendientes.instancia.procesar();
    try {
      final filas = await _cliente
          .from('productos')
          .select()
          .eq('estado', Producto.estadoActivo)
          .order('creado_en', ascending: false)
          .timeout(_tiempoMaximo);
      final productos = filas.map(Producto.fromMap).toList();
      await CacheLocal.guardarProductos(productos);
      return ResultadoProductos(productos, desdeCache: false);
    } catch (e) {
      debugPrint('Catálogo desde caché: $e');
      final cache = await CacheLocal.leerProductos();
      if (cache.isNotEmpty) return ResultadoProductos(cache, desdeCache: true);
      throw const ServicioFallo(
        'No se pudieron cargar las publicaciones. Verifica tu conexión e inténtalo de nuevo.',
      );
    }
  }

  /// Publicaciones del vendedor en sesión, sin importar su estado.
  Future<ResultadoProductos> obtenerMisProductos() async {
    await ColaPendientes.instancia.procesar();
    final usuarioId = _usuarioId;
    if (usuarioId == null) {
      throw const ServicioFallo('Tu sesión no está disponible.');
    }
    try {
      final filas = await _cliente
          .from('productos')
          .select()
          .eq('vendedor_id', usuarioId)
          .order('creado_en', ascending: false)
          .timeout(_tiempoMaximo);
      final productos = filas.map(Producto.fromMap).toList();
      await CacheLocal.guardarMisProductos(productos);
      return ResultadoProductos(productos, desdeCache: false);
    } catch (e) {
      debugPrint('Mis productos desde caché: $e');
      final cache = await CacheLocal.leerMisProductos();
      if (cache.isNotEmpty) return ResultadoProductos(cache, desdeCache: true);
      throw const ServicioFallo(
        'No se pudieron cargar tus publicaciones. Verifica tu conexión e inténtalo de nuevo.',
      );
    }
  }

  /// Identificadores de los productos favoritos del usuario.
  Future<Set<String>> obtenerFavoritos() async {
    final usuarioId = _usuarioId;
    if (usuarioId == null) return <String>{};
    try {
      final filas = await _cliente
          .from('favoritos')
          .select('producto_id')
          .eq('usuario_id', usuarioId)
          .timeout(_tiempoMaximo);
      final remotos = filas.map((f) => f['producto_id'] as String).toSet();
      final ids = await ColaPendientes.instancia.aplicarAFavoritos(remotos);
      await CacheLocal.guardarFavoritos(ids);
      return ids;
    } catch (e) {
      debugPrint('Favoritos desde caché: $e');
      return CacheLocal.leerFavoritos();
    }
  }

  /// Guarda el cambio en local y lo envía cuando sea posible.
  Future<void> registrarFavorito(
      String productoId, {
        required bool agregar,
        required Set<String> favoritos,
      }) async {
    await CacheLocal.guardarFavoritos(favoritos);
    await ColaPendientes.instancia.encolar(
      agregar
          ? ColaPendientes.tipoFavoritoAgregar
          : ColaPendientes.tipoFavoritoQuitar,
      {'producto_id': productoId},
    );
    unawaited(ColaPendientes.instancia.procesar());
  }

  /// Crea una publicación. Devuelve `true` si ya quedó en el servidor y
  /// `false` si quedó pendiente por falta de conexión.
  Future<bool> publicar({
    required String vendedorNombre,
    required String titulo,
    required String descripcion,
    required double precio,
    required String categoria,
    required double latitud,
    required double longitud,
    String? imagenUrl,
  }) async {
    final usuarioId = _usuarioId;
    if (usuarioId == null) {
      throw const ServicioFallo(
        'Tu sesión no está disponible. Inicia sesión de nuevo.',
      );
    }
    await ColaPendientes.instancia.encolar(ColaPendientes.tipoProductoCrear, {
      'vendedor_id': usuarioId,
      'vendedor_nombre': vendedorNombre,
      'titulo': titulo,
      'descripcion': descripcion,
      'precio': precio,
      'categoria': categoria,
      'imagen_url': imagenUrl,
      'latitud': latitud,
      'longitud': longitud,
    });
    await ColaPendientes.instancia.procesar();
    if (ColaPendientes.instancia.ultimoRechazo != null) {
      throw const ServicioFallo(
        'No se pudo crear la publicación. Verifica tus permisos e inténtalo de nuevo.',
      );
    }
    return ColaPendientes.instancia.cantidad == 0;
  }

  Future<void> cambiarEstado(String productoId, String estado) async {
    try {
      await _cliente
          .from('productos')
          .update({'estado': estado})
          .eq('id', productoId)
          .timeout(_tiempoMaximo);
    } catch (e) {
      debugPrint('Error al cambiar estado: $e');
      throw const ServicioFallo(
        'No se pudo actualizar la publicación. Inténtalo de nuevo.',
      );
    }
  }

  Future<void> eliminar(String productoId) async {
    try {
      await _cliente
          .from('productos')
          .delete()
          .eq('id', productoId)
          .timeout(_tiempoMaximo);
    } catch (e) {
      debugPrint('Error al eliminar: $e');
      throw const ServicioFallo(
        'No se pudo eliminar la publicación. Inténtalo de nuevo.',
      );
    }
  }
}