import 'package:flutter/material.dart';

import '../../shared/models/producto.dart';
import '../../shared/services/conectividad_service.dart';
import '../../shared/services/productos_service.dart';
import '../../shared/utils/formato.dart';
import '../../shared/widgets/acciones_sesion.dart';
import '../../shared/widgets/estados_vista.dart';
import '../../shared/widgets/tarjeta_producto.dart';
import 'formulario_producto_page.dart';

/// Panel del vendedor: lista, publica, cambia de estado y elimina sus publicaciones.
class VendedorPage extends StatefulWidget {
  const VendedorPage({super.key});

  @override
  State<VendedorPage> createState() => _VendedorPageState();
}

class _VendedorPageState extends State<VendedorPage> {
  final ProductosService _servicio = ProductosService.instancia;

  List<Producto> _productos = [];
  bool _cargando = true;
  bool _desdeCache = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
    ConectividadService.instancia.enLinea.addListener(_alCambiarConexion);
  }

  @override
  void dispose() {
    ConectividadService.instancia.enLinea.removeListener(_alCambiarConexion);
    super.dispose();
  }

  void _alCambiarConexion() {
    if (ConectividadService.instancia.enLinea.value) _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final resultado = await _servicio.obtenerMisProductos();
      if (!mounted) return;
      setState(() {
        _productos = List.of(resultado.productos);
        _desdeCache = resultado.desdeCache;
      });
    } on ServicioFallo catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  /// Las acciones que modifican datos existentes requieren conexión.
  bool _hayConexion() {
    if (ConectividadService.instancia.enLinea.value) return true;
    _mostrar('Esta acción requiere conexión a internet.');
    return false;
  }

  Future<void> _publicar() async {
    final creada = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const FormularioProductoPage()),
    );
    if (creada == true) _cargar();
  }

  Future<void> _cambiarEstado(Producto producto, String estado) async {
    if (!_hayConexion()) return;
    try {
      await _servicio.cambiarEstado(producto.id, estado);
      await _cargar();
    } on ServicioFallo catch (e) {
      _mostrar(e.mensaje);
    }
  }

  Future<bool> _confirmarEliminacion(Producto producto) async {
    if (!_hayConexion()) return false;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: Text(
          'Se eliminará “${producto.titulo}”. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return false;
    try {
      await _servicio.eliminar(producto.id);
      return true;
    } on ServicioFallo catch (e) {
      _mostrar(e.mensaje);
      return false;
    }
  }

  Widget _tarjeta(Producto producto) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: SizedBox(
          width: 56,
          height: 56,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ImagenProducto(url: producto.imagenUrl),
          ),
        ),
        title: Text(producto.titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${formatearPrecio(producto.precio)} · ${producto.etiquetaEstado}',
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Opciones',
          onSelected: (estado) => _cambiarEstado(producto, estado),
          itemBuilder: (_) => [
            if (producto.estado != Producto.estadoActivo)
              const PopupMenuItem(
                value: Producto.estadoActivo,
                child: Text('Reactivar'),
              ),
            if (producto.estado == Producto.estadoActivo) ...const [
              PopupMenuItem(
                value: Producto.estadoVendido,
                child: Text('Marcar como vendida'),
              ),
              PopupMenuItem(
                value: Producto.estadoOculto,
                child: Text('Ocultar'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _contenido() {
    if (_cargando && _productos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _productos.isEmpty) {
      return VistaError(mensaje: _error!, onReintentar: _cargar);
    }
    if (_productos.isEmpty) {
      return const VistaVacia(
        icono: Icons.inventory_2_outlined,
        mensaje: 'Aún no tienes publicaciones.\nToca “Publicar” para crear la primera.',
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: _productos.length,
        itemBuilder: (context, indice) {
          final producto = _productos[indice];
          return Dismissible(
            key: ValueKey(producto.id),
            direction: DismissDirection.endToStart,
            background: const FondoDeslizar(
              icono: Icons.delete_outline,
              etiqueta: 'Eliminar',
            ),
            confirmDismiss: (_) => _confirmarEliminacion(producto),
            onDismissed: (_) => setState(
                  () => _productos.removeWhere((p) => p.id == producto.id),
            ),
            child: _tarjeta(producto),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis publicaciones'),
        actions: accionesSesion(context),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _publicar,
        icon: const Icon(Icons.add),
        label: const Text('Publicar'),
      ),
      body: Column(
        children: [
          if (_desdeCache)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.history, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Mostrando datos guardados en el dispositivo',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          Expanded(child: _contenido()),
        ],
      ),
    );
  }
}