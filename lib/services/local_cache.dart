import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/spot_item.dart';

/// Acceso centralizado al almacenamiento local (shared_preferences) del modo offline.
///
/// Los datos que pertenecen a un usuario se guardan con su identificador en la clave,
/// de modo que otra sesión en el mismo dispositivo no vea información ajena.
class LocalCache {
  LocalCache._();

  static const String _claveSpotsActivos = 'cache_spots_activos';
  static const String _claveSpotsPropios = 'cache_spots_propios';
  static const String _clavePerfil = 'cache_perfil';
  static const String _clavePendientes = 'cola_publicaciones';
  static const String _claveFavoritos = 'favoritos';

  /// Identificador del usuario autenticado, o `anonimo` si no hay sesión.
  static String get usuarioId {
    try {
      return Supabase.instance.client.auth.currentUser?.id ?? 'anonimo';
    } catch (_) {
      return 'anonimo';
    }
  }

  static String _porUsuario(String base) => '$base:$usuarioId';

  // --- Spots activos (mapa) ---

  static Future<void> guardarSpotsActivos(List<SpotItem> spots) =>
      _guardar(_claveSpotsActivos, spots.map((s) => s.toMap()).toList());

  static Future<List<SpotItem>> leerSpotsActivos() async {
    final datos = await _leer(_claveSpotsActivos);
    if (datos is! List) return [];
    try {
      return datos
          .map((e) => SpotItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('Caché de spots con formato inválido: $e');
      return [];
    }
  }

  // --- Publicaciones propias (perfil) ---

  static Future<void> guardarSpotsPropios(List<Map<String, dynamic>> spots) =>
      _guardar(_porUsuario(_claveSpotsPropios), spots);

  static Future<List<Map<String, dynamic>>> leerSpotsPropios() async {
    final datos = await _leer(_porUsuario(_claveSpotsPropios));
    if (datos is! List) return [];
    return datos
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // --- Perfil ---

  static Future<void> guardarPerfil(Map<String, dynamic> perfil) =>
      _guardar(_porUsuario(_clavePerfil), perfil);

  static Future<Map<String, dynamic>?> leerPerfil() async {
    final datos = await _leer(_porUsuario(_clavePerfil));
    return datos is Map ? Map<String, dynamic>.from(datos) : null;
  }

  // --- Cola de publicaciones pendientes ---
  // Cada elemento almacena el usuario que lo creó.

  static Future<void> guardarPendientes(List<Map<String, dynamic>> cola) =>
      _guardar(_clavePendientes, cola);

  static Future<List<Map<String, dynamic>>> leerPendientes() async {
    final datos = await _leer(_clavePendientes);
    if (datos is! List) return [];
    return datos
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // --- Favoritos ---

  static Future<void> guardarFavoritos(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_porUsuario(_claveFavoritos), ids.toList());
  }

  static Future<Set<String>> leerFavoritos() async {
    final prefs = await SharedPreferences.getInstance();
    final guardados = prefs.getStringList(_porUsuario(_claveFavoritos));
    return (guardados ?? const <String>[]).toSet();
  }

  // --- Utilidades internas ---

  static Future<void> _guardar(String clave, Object valor) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(clave, jsonEncode(valor));
    } catch (e) {
      debugPrint('No se pudo guardar "$clave" en el caché local: $e');
    }
  }

  static Future<Object?> _leer(String clave) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(clave);
      return texto == null ? null : jsonDecode(texto);
    } catch (e) {
      debugPrint('No se pudo leer "$clave" del caché local: $e');
      return null;
    }
  }
}