import 'package:flutter/material.dart';

import '../../shared/models/producto.dart';
import '../../shared/services/catalogo_controller.dart';
import '../../shared/utils/formato.dart';
import 'detalle_producto_page.dart';

/// Menú de opciones que se abre al mantener presionada una publicación.
/// Si se recibe [alDescartar], se ofrece la opción "No me interesa".
void mostrarOpcionesProducto(
    BuildContext context,
    Producto producto, {
      VoidCallback? alDescartar,
    }) {
  final catalogo = CatalogoController.instancia;
  final esFavorito = catalogo.esFavorito(producto.id);

  showModalBottomSheet<void>(
    context: context,
    builder: (contexto) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(producto.titulo,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(formatearPrecio(producto.precio)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Ver detalle'),
            onTap: () {
              Navigator.pop(contexto);
              abrirDetalleProducto(context, producto);
            },
          ),
          ListTile(
            leading: Icon(esFavorito ? Icons.heart_broken : Icons.favorite),
            title: Text(
                esFavorito ? 'Quitar de favoritos' : 'Agregar a favoritos'),
            onTap: () {
              Navigator.pop(contexto);
              catalogo.alternarFavorito(producto.id);
            },
          ),
          if (alDescartar != null)
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('No me interesa'),
              onTap: () {
                Navigator.pop(contexto);
                alDescartar();
              },
            ),
        ],
      ),
    ),
  );
}