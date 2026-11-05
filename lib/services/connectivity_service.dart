import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Expone el estado de red del dispositivo.
///
/// [isOnline] indica si existe una interfaz de red activa (Wi-Fi, datos móviles).
/// Los fallos reales de cada petición se resuelven en los servicios que las realizan.
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Lee el estado inicial y se suscribe a los cambios de conectividad.
  Future<void> iniciar() async {
    await verificar();
    _subscription ??= Connectivity().onConnectivityChanged.listen(_actualizar);
  }

  /// Consulta el estado actual de la red y actualiza [isOnline].
  Future<bool> verificar() async {
    try {
      _actualizar(await Connectivity().checkConnectivity());
    } catch (e) {
      debugPrint('Error al verificar la conectividad: $e');
    }
    return isOnline.value;
  }

  void _actualizar(List<ConnectivityResult> resultados) {
    isOnline.value = resultados.any((r) => r != ConnectivityResult.none);
  }
}