import 'package:flutter/foundation.dart';

import 'local_cache.dart';

/// Favoritos del usuario, guardados en el dispositivo.
class FavoritesService extends ChangeNotifier {
  FavoritesService._();

  static final FavoritesService instance = FavoritesService._();

  Set<String> _ids = <String>{};
  String? _usuarioCargado;

  /// Carga los favoritos del usuario en sesión (solo si cambió el usuario).
  Future<void> cargar() async {
    final usuario = LocalCache.usuarioId;
    if (_usuarioCargado == usuario) return;
    _ids = await LocalCache.leerFavoritos();
    _usuarioCargado = usuario;
    notifyListeners();
  }

  bool esFavorito(String id) => _ids.contains(id);

  /// Agrega o quita un favorito. Devuelve `true` si quedó agregado.
  Future<bool> alternar(String id) async {
    await cargar();
    final agregado = _ids.add(id);
    if (!agregado) _ids.remove(id);
    notifyListeners();
    await LocalCache.guardarFavoritos(_ids);
    return agregado;
  }
}