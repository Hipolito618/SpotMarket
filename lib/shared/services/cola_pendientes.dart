import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cache_local.dart';
import 'conectividad_service.dart';

/// Cola de operaciones pendientes de enviar al servidor.
/// Cada operación se guarda en el dispositivo y se envía en orden
/// cuando hay conexión, de modo que la app opera primero en local.
class ColaPendientes extends ChangeNotifier {
  ColaPendientes._();

  static final ColaPendientes instancia = ColaPendientes._();

  static const String tipoFavoritoAgregar = 'favorito_agregar';
  static const String tipoFavoritoQuitar = 'favorito_quitar';
  static const String tipoProductoCrear = 'producto_crear';

  static const Duration _tiempoMaximo = Duration(seconds: 10);

  List<Map<String, dynamic>> _cola = [];
  String? _usuarioCola;
  Future<void>? _carga;
  Future<void>? _enCurso;
  String? _ultimoRechazo;

  /// Operaciones que aún no se han sincronizado.
  int get cantidad => _cola.length;

  /// Mensaje del último rechazo definitivo del servidor, si ocurrió.
  String? get ultimoRechazo => _ultimoRechazo;

  /// Sincroniza al arrancar y cada vez que vuelve la conexión.
  void iniciar() {
    ConectividadService.instancia.enLinea.addListener(() {
      if (ConectividadService.instancia.enLinea.value) {
        unawaited(procesar());
      }
    });
    unawaited(procesar());
  }

  /// Carga la cola del usuario activo; la recarga si cambió la sesión.
  Future<void> _asegurarCarga() {
    final usuario = CacheLocal.usuarioActual;
    if (_usuarioCola != usuario) {
      _usuarioCola = usuario;
      _cola = [];
      _carga = CacheLocal.leerPendientes().then((guardadas) {
        _cola = guardadas;
        notifyListeners();
      });
    }
    return _carga ?? Future.value();
  }

  Future<void> encolar(String tipo, Map<String, dynamic> datos) async {
    await _asegurarCarga();
    _cola.add({
      'tipo': tipo,
      'datos': datos,
      'fecha': DateTime.now().toIso8601String(),
    });
    notifyListeners();
    await CacheLocal.guardarPendientes(_cola);
  }

  /// Envía las operaciones pendientes. Si ya hay un envío en curso,
  /// devuelve el mismo en lugar de iniciar otro.
  Future<void> procesar() =>
      _enCurso ??= _procesar().whenComplete(() => _enCurso = null);

  Future<void> _procesar() async {
    await _asegurarCarga();
    _ultimoRechazo = null;
    if (Supabase.instance.client.auth.currentUser == null) return;

    while (_cola.isNotEmpty && ConectividadService.instancia.enLinea.value) {
      final operacion = _cola.first;
      try {
        await _enviar(operacion).timeout(_tiempoMaximo);
      } on PostgrestException catch (e) {
        // Un error de sesión es temporal: se conserva la operación.
        if (_esErrorDeSesion(e)) break;
        // Otro rechazo del servidor es definitivo: se descarta para no bloquear la cola.
        debugPrint('Operación descartada (${operacion['tipo']}): ${e.message}');
        _ultimoRechazo = e.message;
      } catch (_) {
        // Fallo de red: se conserva la cola y se reintenta más tarde.
        break;
      }
      if (_cola.isNotEmpty && identical(_cola.first, operacion)) {
        _cola.removeAt(0);
      }
      notifyListeners();
      await CacheLocal.guardarPendientes(_cola);
    }
  }

  bool _esErrorDeSesion(PostgrestException e) {
    return (e.code ?? '').startsWith('PGRST30') ||
        e.message.toLowerCase().contains('jwt');
  }

  Future<void> _enviar(Map<String, dynamic> operacion) async {
    final cliente = Supabase.instance.client;
    final usuarioId = cliente.auth.currentUser?.id;
    if (usuarioId == null) return;
    final datos = Map<String, dynamic>.from(operacion['datos'] as Map);

    switch (operacion['tipo']) {
      case tipoFavoritoAgregar:
        try {
          await cliente.from('favoritos').insert({
            'usuario_id': usuarioId,
            'producto_id': datos['producto_id'],
          });
        } on PostgrestException catch (e) {
          // 23505: el favorito ya existía, el resultado es el esperado.
          if (e.code != '23505') rethrow;
        }
      case tipoFavoritoQuitar:
        await cliente
            .from('favoritos')
            .delete()
            .eq('usuario_id', usuarioId)
            .eq('producto_id', datos['producto_id'] as String);
      case tipoProductoCrear:
        await cliente.from('productos').insert(datos);
    }
  }

  /// Aplica sobre una lista de favoritos remota los cambios aún pendientes.
  Future<Set<String>> aplicarAFavoritos(Set<String> ids) async {
    await _asegurarCarga();
    final resultado = {...ids};
    for (final operacion in _cola) {
      final id = (operacion['datos'] as Map)['producto_id'] as String?;
      if (id == null) continue;
      if (operacion['tipo'] == tipoFavoritoAgregar) resultado.add(id);
      if (operacion['tipo'] == tipoFavoritoQuitar) resultado.remove(id);
    }
    return resultado;
  }
}