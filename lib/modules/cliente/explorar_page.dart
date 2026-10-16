import 'package:flutter/material.dart';

import '../../shared/models/producto.dart';
import '../../shared/services/catalogo_controller.dart';
import '../../shared/widgets/acciones_sesion.dart';
import '../../shared/widgets/estados_vista.dart';
import '../../shared/widgets/tarjeta_producto.dart';
import 'detalle_producto_page.dart';
import 'opciones_producto.dart';

/// Listado de publicaciones con búsqueda, filtro por categoría y gestos.
class ExplorarPage extends StatefulWidget {
  const ExplorarPage({super.key});

  @override
  State<ExplorarPage> createState() => _ExplorarPageState();
}

class _ExplorarPageState extends State<ExplorarPage> {
  final CatalogoController _catalogo = CatalogoController.instancia;
  final TextEditingController _buscador = TextEditingController();
  String _categoria = 'todas';

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  List<Producto> _filtrar() {
    final texto = _buscador.text.trim().toLowerCase();
    return _catalogo.visibles.where((p) {
      final coincideCategoria = _categoria == 'todas' || p.categoria == _categoria;
      final coincideTexto = texto.isEmpty ||
          p.titulo.toLowerCase().contains(texto) ||
          p.descripcion.toLowerCase().contains(texto);
      return coincideCategoria && coincideTexto;
    }).toList();
  }

  void _descartar(Producto producto) {
    _catalogo.descartar(producto.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Publicación descartada'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () => _catalogo.restaurar(producto.id),
        ),
      ),
    );
  }

  Widget _chip(String valor, String etiqueta) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(etiqueta),
        selected: _categoria == valor,
        onSelected: (_) => setState(() => _categoria = valor),
      ),
    );
  }

  Widget _contenido(List<Producto> lista) {
    if (_catalogo.cargando && _catalogo.productos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_catalogo.error != null && _catalogo.productos.isEmpty) {
      return VistaError(
        mensaje: _catalogo.error!,
        onReintentar: _catalogo.cargar,
      );
    }
    if (lista.isEmpty) {
      return VistaVacia(
        icono: Icons.search_off,
        mensaje: _catalogo.productos.isEmpty
            ? 'Todavía no hay publicaciones.'
            : 'No hay publicaciones que coincidan con tu búsqueda.',
      );
    }

    return RefreshIndicator(
      onRefresh: _catalogo.cargar,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: lista.length,
        itemBuilder: (context, indice) {
          final producto = lista[indice];
          return Dismissible(
            key: ValueKey(producto.id),
            direction: DismissDirection.endToStart,
            background: const FondoDeslizar(
              icono: Icons.visibility_off_outlined,
              etiqueta: 'No me interesa',
            ),
            onDismissed: (_) => _descartar(producto),
            child: TarjetaProducto(
              producto: producto,
              esFavorito: _catalogo.esFavorito(producto.id),
              alAbrir: () => abrirDetalleProducto(context, producto),
              alAlternarFavorito: () => _catalogo.alternarFavorito(producto.id),
              alMantener: () => mostrarOpcionesProducto(
                context,
                producto,
                alDescartar: () => _descartar(producto),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar'),
        actions: accionesSesion(context),
      ),
      body: ListenableBuilder(
        listenable: _catalogo,
        builder: (context, _) {
          final lista = _filtrar();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _buscador,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar publicaciones',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _chip('todas', 'Todas'),
                    for (final categoria in categoriasProducto)
                      _chip(categoria, etiquetaCategoria(categoria)),
                  ],
                ),
              ),
              if (_catalogo.desdeCache)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
              Expanded(child: _contenido(lista)),
            ],
          );
        },
      ),
    );
  }
}