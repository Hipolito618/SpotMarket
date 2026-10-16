import 'package:flutter/foundation.dart';

import '../models/producto.dart';
import 'productos_service.dart';

/// Estado compartido del catálogo para las pantallas del cliente
/// (explorar, mapa y favoritos), de modo que se consulta una sola vez.
class CatalogoController extends ChangeNotifier {
  CatalogoController._();

  static final CatalogoController instancia = CatalogoController._();

  List<Producto> _productos = const [];
  Set<String> _idsFavoritos = <String>{};
  final Set<String> _descartados = <String>{};
  bool _cargando = false;
  bool _desdeCache = false;
  String? _error;

  List<Producto> get productos => _productos;

  /// Productos que el usuario no ha descartado.
  List<Producto> get visibles =>
      _productos.where((p) => !_descartados.contains(p.id)).toList();

  List<Producto> get favoritos =>
      _productos.where((p) => _idsFavoritos.contains(p.id)).toList();

  bool get cargando => _cargando;
  bool get desdeCache => _desdeCache;
  String? get error => _error;

  bool esFavorito(String id) => _idsFavoritos.contains(id);

  Future<void> cargar() async {
    if (_cargando) return;
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final resultado = await ProductosService.instancia.obtenerCatalogo();
      _productos = resultado.productos;
      _desdeCache = resultado.desdeCache;
      _idsFavoritos = await ProductosService.instancia.obtenerFavoritos();
    } on ServicioFallo catch (e) {
      _error = e.mensaje;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Actualiza la interfaz de inmediato y luego persiste el cambio.
  Future<void> alternarFavorito(String id) async {
    final agregar = !_idsFavoritos.contains(id);
    _idsFavoritos = {..._idsFavoritos};
    agregar ? _idsFavoritos.add(id) : _idsFavoritos.remove(id);
    notifyListeners();
    await ProductosService.instancia.registrarFavorito(
      id,
      agregar: agregar,
      favoritos: _idsFavoritos,
    );
  }

  void descartar(String id) {
    _descartados.add(id);
    notifyListeners();
  }

  void restaurar(String id) {
    _descartados.remove(id);
    notifyListeners();
  }

  /// Borra el estado en memoria al cerrar sesión.
  void limpiar() {
    _productos = const [];
    _idsFavoritos = <String>{};
    _descartados.clear();
    _desdeCache = false;
    _error = null;
    notifyListeners();
  }
}