import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/producto.dart';

/// Acceso al almacenamiento local para el modo offline.
/// Los datos que pertenecen a un usuario se separan por su identificador.
class CacheLocal {
  CacheLocal._();

  static const String _claveProductos = 'cache_productos';
  static const String _claveMisProductos = 'cache_mis_productos';
  static const String _claveFavoritos = 'cache_favoritos';
  static const String _clavePendientes = 'cola_pendientes';

  /// Identificador del usuario activo, o `anonimo` si no hay sesión.
  static String get usuarioActual =>
      Supabase.instance.client.auth.currentUser?.id ?? 'anonimo';

  static String _claveUsuario(String base) => '$base:$usuarioActual';

  // Catálogo público.
  static Future<void> guardarProductos(List<Producto> productos) =>
      _guardarLista(_claveProductos, productos.map((p) => p.toMap()).toList());

  static Future<List<Producto>> leerProductos() async =>
      _aProductos(await _leerLista(_claveProductos));

  // Publicaciones del vendedor.
  static Future<void> guardarMisProductos(List<Producto> productos) =>
      _guardarLista(
        _claveUsuario(_claveMisProductos),
        productos.map((p) => p.toMap()).toList(),
      );

  static Future<List<Producto>> leerMisProductos() async =>
      _aProductos(await _leerLista(_claveUsuario(_claveMisProductos)));

  // Favoritos.
  static Future<void> guardarFavoritos(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_claveUsuario(_claveFavoritos), ids.toList());
  }

  static Future<Set<String>> leerFavoritos() async {
    final prefs = await SharedPreferences.getInstance();
    final guardados = prefs.getStringList(_claveUsuario(_claveFavoritos));
    return (guardados ?? const <String>[]).toSet();
  }

  // Cola de operaciones pendientes.
  static Future<void> guardarPendientes(List<Map<String, dynamic>> cola) =>
      _guardarLista(_claveUsuario(_clavePendientes), cola);

  static Future<List<Map<String, dynamic>>> leerPendientes() =>
      _leerLista(_claveUsuario(_clavePendientes));

  static List<Producto> _aProductos(List<Map<String, dynamic>> filas) {
    try {
      return filas.map(Producto.fromMap).toList();
    } catch (_) {
      // Un caché con formato inválido se ignora en lugar de romper la app.
      return [];
    }
  }

  static Future<void> _guardarLista(
      String clave,
      List<Map<String, dynamic>> lista,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(clave, jsonEncode(lista));
  }

  static Future<List<Map<String, dynamic>>> _leerLista(String clave) async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(clave);
    if (texto == null) return [];
    try {
      final datos = jsonDecode(texto) as List<dynamic>;
      return datos.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }
}