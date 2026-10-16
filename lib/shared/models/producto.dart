/// Categorías disponibles para las publicaciones.
const List<String> categoriasProducto = [
  'general',
  'electronica',
  'hogar',
  'deportes',
  'musica',
  'ropa',
  'vehiculos',
];

const Map<String, String> _etiquetasCategoria = {
  'general': 'General',
  'electronica': 'Electrónica',
  'hogar': 'Hogar',
  'deportes': 'Deportes',
  'musica': 'Música',
  'ropa': 'Ropa',
  'vehiculos': 'Vehículos',
};

/// Nombre legible de una categoría.
String etiquetaCategoria(String categoria) =>
    _etiquetasCategoria[categoria] ?? categoria;

/// Publicación del marketplace.
class Producto {
  const Producto({
    required this.id,
    required this.vendedorId,
    required this.vendedorNombre,
    required this.titulo,
    required this.descripcion,
    required this.precio,
    required this.categoria,
    required this.latitud,
    required this.longitud,
    required this.estado,
    required this.creadoEn,
    this.imagenUrl,
  });

  static const String estadoActivo = 'activo';
  static const String estadoVendido = 'vendido';
  static const String estadoOculto = 'oculto';

  final String id;
  final String vendedorId;
  final String vendedorNombre;
  final String titulo;
  final String descripcion;
  final double precio;
  final String categoria;
  final String? imagenUrl;
  final double latitud;
  final double longitud;
  final String estado;
  final DateTime creadoEn;

  String get etiquetaEstado {
    if (estado == estadoVendido) return 'Vendida';
    if (estado == estadoOculto) return 'Oculta';
    return 'Activa';
  }

  factory Producto.fromMap(Map<String, dynamic> mapa) {
    return Producto(
      id: mapa['id'] as String,
      vendedorId: mapa['vendedor_id'] as String,
      vendedorNombre: mapa['vendedor_nombre'] as String,
      titulo: mapa['titulo'] as String,
      descripcion: (mapa['descripcion'] as String?) ?? '',
      precio: (mapa['precio'] as num).toDouble(),
      categoria: (mapa['categoria'] as String?) ?? 'general',
      imagenUrl: mapa['imagen_url'] as String?,
      latitud: (mapa['latitud'] as num).toDouble(),
      longitud: (mapa['longitud'] as num).toDouble(),
      estado: (mapa['estado'] as String?) ?? estadoActivo,
      creadoEn: DateTime.parse(mapa['creado_en'] as String),
    );
  }

  /// Representación serializable, usada para el caché local.
  Map<String, dynamic> toMap() => {
    'id': id,
    'vendedor_id': vendedorId,
    'vendedor_nombre': vendedorNombre,
    'titulo': titulo,
    'descripcion': descripcion,
    'precio': precio,
    'categoria': categoria,
    'imagen_url': imagenUrl,
    'latitud': latitud,
    'longitud': longitud,
    'estado': estado,
    'creado_en': creadoEn.toIso8601String(),
  };
}