import 'package:flutter/material.dart';

import '../../shared/models/producto.dart';
import '../../shared/services/catalogo_controller.dart';
import '../../shared/utils/formato.dart';
import '../../shared/widgets/tarjeta_producto.dart';

/// Abre el detalle de una publicación.
void abrirDetalleProducto(BuildContext context, Producto producto) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DetalleProductoPage(producto: producto),
    ),
  );
}

class DetalleProductoPage extends StatelessWidget {
  const DetalleProductoPage({super.key, required this.producto});

  final Producto producto;

  @override
  Widget build(BuildContext context) {
    final catalogo = CatalogoController.instancia;
    final tema = Theme.of(context);

    return ListenableBuilder(
      listenable: catalogo,
      builder: (context, _) {
        final esFavorito = catalogo.esFavorito(producto.id);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalle'),
            actions: [
              IconButton(
                tooltip: esFavorito
                    ? 'Quitar de favoritos'
                    : 'Agregar a favoritos',
                icon: Icon(
                  esFavorito ? Icons.favorite : Icons.favorite_border,
                  color: esFavorito ? Colors.redAccent : null,
                ),
                onPressed: () => catalogo.alternarFavorito(producto.id),
              ),
            ],
          ),
          body: ListView(
            children: [
              // Pellizcar para ampliar la imagen.
              AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRect(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: ImagenProducto(
                      url: producto.imagenUrl,
                      ajuste: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(producto.titulo, style: tema.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      formatearPrecio(producto.precio),
                      style: tema.textTheme.titleLarge?.copyWith(
                        color: tema.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: Text(etiquetaCategoria(producto.categoria))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Publicado por ${producto.vendedorNombre}'),
                    Text('Fecha: ${formatearFecha(producto.creadoEn)}'),
                    const Divider(height: 32),
                    Text(
                      producto.descripcion.isEmpty
                          ? 'Sin descripción.'
                          : producto.descripcion,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}