import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/perfil.dart';

/// Error de autenticación con mensaje listo para mostrar al usuario.
class AuthFallo implements Exception {
  const AuthFallo(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Gestiona sesión, registro y perfil del usuario.
/// Notifica a los oyentes (por ejemplo, el router) cuando cambia el estado.
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instancia = AuthService._();

  static const String _clavePerfilCache = 'perfil_cache';

  final SupabaseClient _cliente = Supabase.instance.client;
  Perfil? _perfil;

  Perfil? get perfil => _perfil;

  bool get autenticado => _cliente.auth.currentSession != null;

  /// Rol vigente. Si el perfil aún no está disponible se asume el rol base.
  RolUsuario get rol => _perfil?.rol ?? RolUsuario.cliente;

  /// Restaura el perfil de la sesión existente y escucha cierres de sesión.
  Future<void> iniciar() async {
    if (autenticado) {
      await _cargarPerfil();
    }
    _cliente.auth.onAuthStateChange.listen((estado) async {
      if (estado.event == AuthChangeEvent.signedOut) {
        await _limpiarSesionLocal();
        notifyListeners();
      }
    });
  }

  Future<void> iniciarSesion({
    required String correo,
    required String clave,
  }) async {
    await _ejecutar(() async {
      await _cliente.auth.signInWithPassword(email: correo, password: clave);
      await _cargarPerfil();
    });
    notifyListeners();
  }

  /// Registra un usuario con rol base. Devuelve `true` si la sesión
  /// quedó iniciada y `false` si se requiere confirmar el correo.
  Future<bool> registrar({
    required String nombre,
    required String correo,
    required String clave,
  }) async {
    final sesionIniciada = await _ejecutar(() async {
      final respuesta = await _cliente.auth.signUp(
        email: correo,
        password: clave,
        data: {'nombre': nombre},
      );
      if (respuesta.session == null) return false;
      await _cargarPerfil();
      return true;
    });
    notifyListeners();
    return sesionIniciada;
  }

  Future<void> cerrarSesion() async {
    await _cliente.auth.signOut();
    await _limpiarSesionLocal();
    notifyListeners();
  }

  /// Obtiene el perfil desde Supabase y lo respalda localmente.
  /// Sin conexión, usa el último perfil guardado del mismo usuario.
  Future<void> _cargarPerfil() async {
    final usuario = _cliente.auth.currentUser;
    if (usuario == null) return;

    final prefs = await SharedPreferences.getInstance();
    try {
      final datos = await _cliente
          .from('perfiles')
          .select()
          .eq('id', usuario.id)
          .single();
      _perfil = Perfil.fromMap(datos);
      await prefs.setString(_clavePerfilCache, jsonEncode(_perfil!.toMap()));
    } catch (_) {
      final respaldo = prefs.getString(_clavePerfilCache);
      if (respaldo != null) {
        final perfilGuardado =
        Perfil.fromMap(jsonDecode(respaldo) as Map<String, dynamic>);
        if (perfilGuardado.id == usuario.id) _perfil = perfilGuardado;
      }
    }
  }

  Future<void> _limpiarSesionLocal() async {
    _perfil = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clavePerfilCache);
  }

  /// Ejecuta una acción y convierte los errores en mensajes en español.
  Future<T> _ejecutar<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on AuthException catch (e) {
      throw AuthFallo(_traducir(e));
    } catch (_) {
      throw const AuthFallo(
        'No fue posible conectar con el servidor. Verifica tu conexión a internet.',
      );
    }
  }

  String _traducir(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'Correo o contraseña incorrectos.';
      case 'user_already_exists':
        return 'Este correo ya está registrado.';
      case 'weak_password':
        return 'La contraseña es demasiado débil.';
      case 'email_not_confirmed':
        return 'Confirma tu correo antes de iniciar sesión.';
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
      default:
        return 'No se pudo completar la operación. Verifica tu conexión e inténtalo de nuevo.';
    }
  }
}