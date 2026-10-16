import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../utils/formato.dart';

/// Imagen de una publicación con marcador de posición si no hay imagen
/// o no se puede cargar.
class ImagenProducto extends StatelessWidget {
  const ImagenProducto({super.key, this.url, this.ajuste = BoxFit.cover});

  final String? url;
  final BoxFit ajuste;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final marcador = ColoredBox(
      color: esquema.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.image_outlined,
            size: 40, color: esquema.onSurfaceVariant),
      ),
    );

    final direccion = url;
    if (direccion == null || direccion.isEmpty) return marcador;

    return Image.network(
      direccion,
      fit: ajuste,
      errorBuilder: (_, __, ___) => marcador,
      loadingBuilder: (_, hijo, progreso) => progreso == null ? hijo : marcador,
    );
  }
}

/// Tarjeta de una publicación. Los gestos se delegan a quien la usa:
/// tap abre, doble tap marca favorito y mantener presionado abre opciones.
class TarjetaProducto extends StatelessWidget {
  const TarjetaProducto({
    super.key,
    required this.producto,
    required this.esFavorito,
    required this.alAbrir,
    required this.alAlternarFavorito,
    required this.alMantener,
  });

  final Producto producto;
  final bool esFavorito;
  final VoidCallback alAbrir;
  final VoidCallback alAlternarFavorito;
  final VoidCallback alMantener;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alAbrir,
        onDoubleTap: alAlternarFavorito,
        onLongPress: alMantener,
        child: Row(
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: ImagenProducto(url: producto.imagenUrl),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatearPrecio(producto.precio),
                      style: tema.textTheme.titleSmall?.copyWith(
                        color: tema.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${etiquetaCategoria(producto.categoria)} · ${producto.vendedorNombre}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                esFavorito ? Icons.favorite : Icons.favorite_border,
                color: esFavorito ? Colors.redAccent : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fondo mostrado al deslizar una tarjeta para descartarla.
class FondoDeslizar extends StatelessWidget {
  const FondoDeslizar({super.key, required this.icono, required this.etiqueta});

  final IconData icono;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: esquema.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(etiqueta,
                style: TextStyle(color: esquema.onSecondaryContainer)),
            const SizedBox(width: 8),
            Icon(icono, color: esquema.onSecondaryContainer),
          ],
        ),
      ),
    );
  }
}