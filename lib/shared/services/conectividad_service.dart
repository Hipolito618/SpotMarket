import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Expone el estado de la conexión a internet del dispositivo.
/// Indica si hay una interfaz de red activa; los fallos reales de
/// las peticiones se manejan en cada servicio.
class ConectividadService {
  ConectividadService._();

  static final ConectividadService instancia = ConectividadService._();

  final ValueNotifier<bool> enLinea = ValueNotifier<bool>(true);
  StreamSubscription<List<ConnectivityResult>>? _suscripcion;

  Future<void> iniciar() async {
    enLinea.value = _hayRed(await Connectivity().checkConnectivity());
    _suscripcion ??= Connectivity().onConnectivityChanged.listen(
          (resultados) => enLinea.value = _hayRed(resultados),
    );
  }

  bool _hayRed(List<ConnectivityResult> resultados) {
    return resultados.any((r) => r != ConnectivityResult.none);
  }
}