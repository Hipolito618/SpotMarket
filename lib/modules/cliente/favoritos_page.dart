import 'package:flutter/material.dart';

import '../../shared/services/catalogo_controller.dart';
import '../../shared/widgets/acciones_sesion.dart';
import '../../shared/widgets/estados_vista.dart';
import '../../shared/widgets/tarjeta_producto.dart';
import 'detalle_producto_page.dart';
import 'opciones_producto.dart';

/// Publicaciones marcadas como favoritas. Deslizar las quita de la lista.
class FavoritosPage extends StatelessWidget {
  const FavoritosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final catalogo = CatalogoController.instancia;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
        actions: accionesSesion(context),
      ),
      body: ListenableBuilder(
        listenable: catalogo,
        builder: (context, _) {
          if (catalogo.cargando && catalogo.productos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final lista = catalogo.favoritos;
          if (lista.isEmpty) {
            return const VistaVacia(
              icono: Icons.favorite_border,
              mensaje:
              'Aún no tienes favoritos.\nDa doble toque a una publicación para guardarla.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: lista.length,
            itemBuilder: (context, indice) {
              final producto = lista[indice];
              return Dismissible(
                key: ValueKey(producto.id),
                direction: DismissDirection.endToStart,
                background: const FondoDeslizar(
                  icono: Icons.heart_broken,
                  etiqueta: 'Quitar',
                ),
                onDismissed: (_) => catalogo.alternarFavorito(producto.id),
                child: TarjetaProducto(
                  producto: producto,
                  esFavorito: true,
                  alAbrir: () => abrirDetalleProducto(context, producto),
                  alAlternarFavorito: () =>
                      catalogo.alternarFavorito(producto.id),
                  alMantener: () => mostrarOpcionesProducto(context, producto),
                ),
              );
            },
          );
        },
      ),
    );
  }
}