import 'package:latlong2/latlong.dart' hide Path;

/// Tipo de puesto o vendedor en spotMarket
enum SpotType {
  /// Local establecido o puesto fijo en la colonia (ej. tamales en la esquina, local comercial)
  localBusiness,

  /// Vendedor particular de segunda mano, bazar móvil o trueque
  reseller,
}

/// Modelo de datos representativo de un artículo o puesto hiperlocal
class SpotItem {
  final String id;
  final String title;
  final double price;
  final SpotType type;
  final String category;
  final String distance;
  final String? exactAddress;
  final List<String>? meetingPoints;
  final String? imageUrl;
  final LatLng? position;
  final String? description;
  final bool isOpen;
  final bool hasDelivery;
  final String? deliveryCost;

  const SpotItem({
    required this.id,
    required this.title,
    required this.price,
    required this.type,
    required this.category,
    required this.distance,
    this.exactAddress,
    this.meetingPoints,
    this.imageUrl,
    this.position,
    this.description,
    this.isOpen = true,
    this.hasDelivery = false,
    this.deliveryCost,
  });

  /// Precio con formato estándar en pesos mexicanos
  String get formattedPrice => '\$${price.toStringAsFixed(0)} MXN';

  /// Indica si es un puesto fijo o negocio local
  bool get isLocalBusiness => type == SpotType.localBusiness;

  /// Indica si es un vendedor particular / segunda mano
  bool get isReseller => type == SpotType.reseller;
  /// Crea una copia de este SpotItem con valores modificados
  SpotItem copyWith({
    String? id,
    String? title,
    double? price,
    SpotType? type,
    String? category,
    String? distance,
    String? exactAddress,
    List<String>? meetingPoints,
    String? imageUrl,
    LatLng? position,
    String? description,
    bool? isOpen,
    bool? hasDelivery,
    String? deliveryCost,
  }) {
    return SpotItem(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      type: type ?? this.type,
      category: category ?? this.category,
      distance: distance ?? this.distance,
      exactAddress: exactAddress ?? this.exactAddress,
      meetingPoints: meetingPoints ?? this.meetingPoints,
      imageUrl: imageUrl ?? this.imageUrl,
      position: position ?? this.position,
      description: description ?? this.description,
      isOpen: isOpen ?? this.isOpen,
      hasDelivery: hasDelivery ?? this.hasDelivery,
      deliveryCost: deliveryCost ?? this.deliveryCost,
    );
  }
}

