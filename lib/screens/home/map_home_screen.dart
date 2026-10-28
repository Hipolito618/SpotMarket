import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../core/controllers/theme_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/spot_item.dart';
import '../../widgets/spot_preview_modal.dart';
import '../spots/add_spot_screen.dart';

enum MarketCategory { todos, antojitos, bazar, abiertoAhora }

class MapHomeScreen extends StatefulWidget {
  const MapHomeScreen({super.key});

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<MapHomeScreen> {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  StreamSubscription<Position>? _positionStreamSub;

  // Ubicación por defecto de respaldo en San Luis Potosí centro (Lat: 22.1565, Lng: -100.9855)
  static const LatLng _defaultLocation = LatLng(22.1565, -100.9855);

  LatLng _userLocation = _defaultLocation;
  bool _hasGpsLocation = false;

  MarketCategory _selectedCategory = MarketCategory.todos;
  SpotItem? _selectedSpot;
  double _currentSheetSize = 0.18;

  // --- PINES DE PRUEBA EN SAN LUIS POTOSÍ ---
  late final List<SpotItem> _spots = [
    // A) ZONA CENTRO / EJE VIAL / ALAMEDA (Ubicación exacta de la conexión SLP)
    SpotItem(
      id: 'slp_centro_1',
      title: 'Enchiladas Potosinas y Antojitos La Alameda',
      price: 55.0,
      type: SpotType.localBusiness,
      category: 'Antojitos',
      distance: 'a 95 m',
      exactAddress: 'Av. Universidad 180, Col. Alameda / Centro, SLP',
      position: LatLng(22.1525, -100.9715),
      imageUrl: 'https://images.unsplash.com/photo-1551782450-a2132b4ba21d?w=200&q=80',
      description: 'Enchiladas potosinas tradicionales con cecina, frijoles refritos y cueritos.',
      isOpen: true,
    ),
    SpotItem(
      id: 'slp_centro_2',
      title: 'Bazar Urbano Ropa y Calzado Vintage',
      price: 85.0,
      type: SpotType.reseller,
      category: 'Bazar',
      distance: 'a 140 m',
      meetingPoints: ['Kiosco Alameda Central', 'Plaza del Carmen', 'Cineteca Alameda'],
      position: LatLng(22.1508, -100.9732),
      imageUrl: 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=200&q=80',
      description: 'Prendas vintage unisex, sneakers retro y accesorios artesanales.',
      isOpen: true,
    ),
    SpotItem(
      id: 'slp_centro_3',
      title: 'Raspados y Helados Artesanales El Sol',
      price: 35.0,
      type: SpotType.localBusiness,
      category: 'Antojitos',
      distance: 'a 210 m',
      exactAddress: 'Calle Manuel José Othón 310, Centro, SLP',
      position: LatLng(22.1532, -100.9730),
      imageUrl: 'https://images.unsplash.com/photo-1501443762994-82bd5dace89a?w=200&q=80',
      description: 'Nieve artesanal de garambullo, guanábana y raspados de rompope con nuez.',
      isOpen: true,
    ),
    SpotItem(
      id: 'slp_centro_4',
      title: 'Chácharas y Bazar Don Pepe',
      price: 110.0,
      type: SpotType.reseller,
      category: 'Segunda mano',
      distance: 'a 280 m',
      meetingPoints: ['Glorieta Bocanegra', 'Estación Ferrocarril', 'OXXO Eje Vial'],
      position: LatLng(22.1498, -100.9712),
      imageUrl: 'https://images.unsplash.com/photo-1588702547923-7093a6c3ba33?w=200&q=80',
      description: 'Relojes antiguos, herramientas para el hogar, juguetes coleccionables y cables.',
      isOpen: true,
    ),

    // B) ZONA COLONIA POPULAR (SLP)
    SpotItem(
      id: 'slp_pop_1',
      title: 'Raspas y Antojitos Doña Lolis',
      price: 35.0,
      type: SpotType.localBusiness,
      category: 'Antojitos',
      distance: 'a 1.8 km',
      exactAddress: 'Calle Durango 410, Col. Popular, SLP',
      position: LatLng(22.1645, -100.9620),
      imageUrl: 'https://images.unsplash.com/photo-1501443762994-82bd5dace89a?w=200&q=80',
      description: 'Raspados artesanales de fresa, tamarindo y durazno con leche condensada y chilitos.',
      isOpen: true,
    ),
    SpotItem(
      id: 'slp_pop_2',
      title: 'Bazar de Garage Ropa Vintage',
      price: 90.0,
      type: SpotType.reseller,
      category: 'Bazar',
      distance: 'a 1.9 km',
      meetingPoints: ['OXXO Plaza San Luis', 'Kiosco Central Col. Popular', 'Parque Morales'],
      position: LatLng(22.1630, -100.9605),
      imageUrl: 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=200&q=80',
      description: 'Chamarras noventeras, jeans mom fit y playeras de bandas de rock.',
      isOpen: true,
    ),
    SpotItem(
      id: 'slp_pop_3',
      title: 'Elotes y Esquites El Chino',
      price: 40.0,
      type: SpotType.localBusiness,
      category: 'Antojitos',
      distance: 'a 2.1 km',
      exactAddress: 'Av. México esq. Col. Popular, SLP',
      position: LatLng(22.1660, -100.9640),
      imageUrl: 'https://images.unsplash.com/photo-1551782450-a2132b4ba21d?w=200&q=80',
      description: 'Esquites con tuétano, chile del que pica y del que no pica, epazote y mayonesa con limón.',
      isOpen: true,
    ),

    // C) ZONA UNIVERSITARIA UASLP (Niño Artillero / Manuel Nava)
    SpotItem(
      id: 'slp_uaslp_1',
      title: 'Copias, Calculadoras y Chácharas de Inge',
      price: 120.0,
      type: SpotType.reseller,
      category: 'Segunda mano',
      distance: 'a 4.8 km',
      meetingPoints: ['Facultad de Ingeniería UASLP', 'Glorieta González Bocanegra', 'Edificio Central UASLP'],
      position: LatLng(22.1495, -101.0185),
      imageUrl: 'https://images.unsplash.com/photo-1588702547923-7093a6c3ba33?w=200&q=80',
      description: 'Calculadoras científicas, reglas T, batas de laboratorio y adaptadores.',
      isOpen: true,
    ),
    SpotItem(
      id: 'slp_uaslp_2',
      title: 'Tortas y Gorditas El Estudiante',
      price: 45.0,
      type: SpotType.localBusiness,
      category: 'Antojitos',
      distance: 'a 4.6 km',
      exactAddress: 'Av. Manuel Nava 205, Zona Universitaria, SLP',
      position: LatLng(22.1480, -101.0160),
      imageUrl: 'https://images.unsplash.com/photo-1551782450-a2132b4ba21d?w=200&q=80',
      description: 'Gorditas de chicharrón prensado, deshebrada y tortas calientes recién hechas.',
      isOpen: true,
    ),
    SpotItem(
      id: 'slp_uaslp_3',
      title: 'Remate de Libros y Apuntes',
      price: 70.0,
      type: SpotType.reseller,
      category: 'Bazar',
      distance: 'a 5.0 km',
      meetingPoints: ['Entrada Niño Artillero', 'Cafetería Central UASLP', 'Plaza del Ángel'],
      position: LatLng(22.1510, -101.0200),
      imageUrl: 'https://images.unsplash.com/photo-1539185441755-769473a23570?w=200&q=80',
      description: 'Libros de cálculo, física, medicina, formularios y novelas clásicas.',
      isOpen: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _sheetController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Inicializa la posición GPS y configura el fallback seguro
  Future<void> _initLocation() async {
    try {
      final Position? position = await _determinePosition();
      if (position != null && mounted) {
        final LatLng userPos = LatLng(position.latitude, position.longitude);
        setState(() {
          _userLocation = userPos;
          _hasGpsLocation = true;
        });
        // Centrado inicial de la cámara al obtener la primera lectura exitosa
        _mapController.move(userPos, 15.5);
        _startPositionStream();
      } else if (mounted) {
        // Fallback de respaldo en San Luis Potosí centro (Lat: 22.1565, Lng: -100.9855) con zoom 14.5
        setState(() {
          _userLocation = _defaultLocation;
          _hasGpsLocation = false;
        });
        _mapController.move(_defaultLocation, 14.5);
      }
    } catch (e) {
      debugPrint('Error en inicialización de ubicación: $e');
      if (mounted) {
        setState(() {
          _userLocation = _defaultLocation;
          _hasGpsLocation = false;
        });
        _mapController.move(_defaultLocation, 14.5);
      }
    }
  }

  /// Función dedicada: Manejo seguro de permisos y servicio GPS
  Future<Position?> _determinePosition() async {
    // 1. Verifica si el servicio de ubicación del dispositivo está activo
    bool serviceEnabled = false;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Error al verificar servicio de ubicación: $e');
      return null;
    }

    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'El servicio de ubicación GPS está desactivado. Actívalo para ubicarte en el mapa.',
            ),
            action: SnackBarAction(
              label: 'Activar',
              onPressed: () => Geolocator.openLocationSettings(),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return null;
    }

    // 2. Evalúa el estado de permisos
    LocationPermission permission;
    try {
      permission = await Geolocator.checkPermission();
    } catch (e) {
      debugPrint('Error al consultar permisos de ubicación: $e');
      return null;
    }

    if (permission == LocationPermission.denied) {
      try {
        permission = await Geolocator.requestPermission();
      } catch (e) {
        debugPrint('Error al solicitar permiso de ubicación: $e');
        return null;
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Permiso de ubicación denegado. Mostrando vista general en San Luis Potosí.',
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showPermissionDeniedForeverAlert();
      }
      return null;
    }

    // 3. Con permisos concedidos, obtiene la posición actual con LocationAccuracy.high
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (e) {
      debugPrint('Timeout o fallo obteniendo coordenadas GPS: $e');
      return null;
    }
  }

  /// Alerta explicando que los permisos de ubicación están deshabilitados permanentemente
  void _showPermissionDeniedForeverAlert() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF22201D) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD81B60).withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_off_rounded, color: Color(0xFFD81B60), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ubicación requerida',
                  style: GoogleFonts.rubik(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Los permisos de ubicación están deshabilitados permanentemente. Para poder mostrarte tu posición exacta y los bazares cercanos en el mapa, habilítalos desde los ajustes de la aplicación.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancelar',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                Geolocator.openAppSettings();
              },
              icon: const Icon(Icons.settings_rounded, size: 18),
              label: Text(
                'Abrir Ajustes',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF05A24),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Suscripción al stream de seguimiento en tiempo real con distanceFilter: 10
  void _startPositionStream() {
    _positionStreamSub?.cancel();
    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (Position position) {
        if (!mounted) return;
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _hasGpsLocation = true;
        });
      },
      onError: (dynamic error) {
        debugPrint('Error en stream de seguimiento GPS: $error');
      },
    );
  }

  /// Calcula y formatea la distancia exacta en metros o kilómetros respecto a la ubicación del usuario
  String _formatExactDistance(SpotItem spot) {
    if (spot.position == null) return spot.distance;
    final meters = const Distance().as(LengthUnit.Meter, _userLocation, spot.position!);
    if (meters < 1000) {
      return 'a ${meters.round()} m';
    } else {
      return 'a ${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  List<SpotItem> get _filteredSpots {
    List<SpotItem> list;
    switch (_selectedCategory) {
      case MarketCategory.todos:
        list = List.of(_spots);
        break;
      case MarketCategory.antojitos:
        list = _spots.where((s) => s.category.toLowerCase().contains('antojitos') || s.type == SpotType.localBusiness).toList();
        break;
      case MarketCategory.bazar:
        list = _spots.where((s) => s.category.toLowerCase().contains('bazar') || s.category.toLowerCase().contains('segunda') || s.type == SpotType.reseller).toList();
        break;
      case MarketCategory.abiertoAhora:
        list = _spots.where((s) => s.isOpen).toList();
        break;
    }

    // Ordenar automáticamente por distancia exacta a la ubicación del usuario (más cercanos primero)
    list.sort((a, b) {
      if (a.position == null || b.position == null) return 0;
      final distA = const Distance().as(LengthUnit.Meter, _userLocation, a.position!);
      final distB = const Distance().as(LengthUnit.Meter, _userLocation, b.position!);
      return distA.compareTo(distB);
    });

    return list;
  }

  /// Al tocar un marcador, centra la cámara exactamente en el puesto y abre SpotPreviewModal con distancia exacta
  void _onSpotSelected(SpotItem spot) {
    setState(() => _selectedSpot = spot);
    if (spot.position != null) {
      _mapController.move(spot.position!, 15.5);
    }
    final spotWithExactDist = spot.copyWith(distance: _formatExactDistance(spot));
    SpotPreviewModal.show(context, spotWithExactDist);
  }

  /// Recentra la cámara instantáneamente hacia la última coordenada conocida del usuario
  Future<void> _recenterToUser() async {
    try {
      if (_hasGpsLocation) {
        _mapController.move(_userLocation, 15.5);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Centrado en tu ubicación GPS (${_userLocation.latitude.toStringAsFixed(4)}, ${_userLocation.longitude.toStringAsFixed(4)})',
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        // Si aún no se cuenta con GPS, intentar determinar la posición
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Buscando señal GPS en tiempo real...'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        final Position? pos = await _determinePosition();
        if (pos != null && mounted) {
          final LatLng newPos = LatLng(pos.latitude, pos.longitude);
          setState(() {
            _userLocation = newPos;
            _hasGpsLocation = true;
          });
          _mapController.move(newPos, 15.5);
          _startPositionStream();
        } else if (mounted) {
          _mapController.move(_userLocation, 14.5);
        }
      }
    } catch (e) {
      debugPrint('Error al recentrar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final secondaryColor = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    // Servidor OpenStreetMap oficial (100% libre, sin marcas de agua ni API key)
    const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Scaffold(
      body: Stack(
        children: [
          // 1. LIENZO DEL MAPA A PANTALLA COMPLETA
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultLocation,
              initialZoom: 14.5,
              onTap: (tapPosition, point) {
                if (_selectedSpot != null) {
                  setState(() => _selectedSpot = null);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.spotmarket.app',
                maxZoom: 19,
                tileBuilder: isDark
                    ? (context, tileWidget, tile) {
                        return ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            -0.80, 0, 0, 0, 240, // Red cálido invertido
                            0, -0.80, 0, 0, 235, // Green suave
                            0, 0, -0.80, 0, 225, // Blue reducido para tono carbón cálido
                            0, 0, 0, 1, 0,       // Alpha intacto
                          ]),
                          child: tileWidget,
                        );
                      }
                    : null,
              ),
              MarkerLayer(
                markers: [
                  // Marcador GPS del usuario en tiempo real (Punto azul con halo de precisión animado)
                  Marker(
                    point: _userLocation,
                    width: 48,
                    height: 48,
                    child: const _UserGpsMarker(),
                  ),

                  // Marcadores de puestos hiperlocales en San Luis Potosí
                  ..._filteredSpots.where((s) => s.position != null).map((spot) {
                    final isBazar = spot.type == SpotType.reseller || spot.category.toLowerCase().contains('bazar');
                    final pinColor = isBazar ? secondaryColor : primaryColor;
                    final isSelected = _selectedSpot?.id == spot.id;

                    return Marker(
                      point: spot.position!,
                      width: isSelected ? 52 : 44,
                      height: isSelected ? 62 : 54,
                      alignment: Alignment.topCenter,
                      child: _SpotTeardropMarker(
                        pinColor: pinColor,
                        category: spot.category,
                        title: spot.title,
                        isSelected: isSelected,
                        onTap: () => _onSpotSelected(spot),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // 2. CAPA SUPERIOR FLOTANTE (Barra de búsqueda + Chips horizontales)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Barra de búsqueda cápsula flotante
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isDark ? const Color(0xFF38342F) : const Color(0xFFEBE6DC),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 50 : 16),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: textSecondary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '¿Qué buscas en tu colonia?',
                            style: GoogleFonts.plusJakartaSans(
                              color: textSecondary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.tune_rounded,
                            color: textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Filtros avanzados de colonia (SLP) próximamente.'),
                                backgroundColor: primaryColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

                  const SizedBox(height: 10),

                  // Fila de chips de categorías filtrables
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildCategoryFilterChip(
                          label: '🔥 Todos',
                          category: MarketCategory.todos,
                          isSelected: _selectedCategory == MarketCategory.todos,
                          primaryColor: primaryColor,
                          surfaceColor: surfaceColor,
                          textPrimary: textPrimary,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryFilterChip(
                          label: '🍧 Antojitos',
                          category: MarketCategory.antojitos,
                          isSelected: _selectedCategory == MarketCategory.antojitos,
                          primaryColor: primaryColor,
                          surfaceColor: surfaceColor,
                          textPrimary: textPrimary,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryFilterChip(
                          label: '👗 Bazar',
                          category: MarketCategory.bazar,
                          isSelected: _selectedCategory == MarketCategory.bazar,
                          primaryColor: primaryColor,
                          surfaceColor: surfaceColor,
                          textPrimary: textPrimary,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryFilterChip(
                          label: '🟢 Abierto ahora',
                          category: MarketCategory.abiertoAhora,
                          isSelected: _selectedCategory == MarketCategory.abiertoAhora,
                          primaryColor: primaryColor,
                          surfaceColor: surfaceColor,
                          textPrimary: textPrimary,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: -0.1, end: 0),
                ],
              ),
            ),
          ),

          // 3. CONTROLES FLOTANTES LATERALES
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            right: 16,
            bottom: (_currentSheetSize > 0.3) ? -100 : 160,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Botón circular para centrar GPS en tiempo real
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _recenterToUser,
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 60 : 20),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? const Color(0xFF38342F) : const Color(0xFFEBE6DC),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.my_location_rounded,
                        color: _hasGpsLocation ? const Color(0xFF1E88E5) : textPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Botón circular para alternar Modo Claro / Modo Oscuro
                _buildFloatingThemeButton(isDark, surfaceColor),

                const SizedBox(height: 16),

                // Botón principal flotante "+ Vender"
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final newSpot = await Navigator.push<SpotItem>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddSpotScreen(initialLocation: _userLocation),
                        ),
                      );

                      if (!mounted || newSpot == null) return;

                      setState(() {
                        _spots.insert(0, newSpot);
                        _selectedSpot = newSpot;
                      });

                      if (newSpot.position != null) {
                        _mapController.move(newSpot.position!, 16.5);
                      }

                      messenger.hideCurrentSnackBar();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('¡"${newSpot.title}" agregado con éxito al mapa!'),
                          backgroundColor: primaryColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withAlpha(isDark ? 90 : 120),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 6),
                          Text(
                            'Vender',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. HOJA DESLIZABLE INFERIOR (DraggableScrollableSheet)
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              setState(() {
                _currentSheetSize = notification.extent;
              });
              return true;
            },
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.18,
              minChildSize: 0.18,
              maxChildSize: 0.80,
              snap: true,
              snapSizes: const [0.18, 0.45, 0.80],
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                    border: isDark
                        ? const Border(top: BorderSide(color: Color(0xFF38342F), width: 1))
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 90 : 25),
                        blurRadius: 18,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // 'Drag handle' central
                      Center(
                        child: Container(
                          width: 40,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF4A4640) : const Color(0xFFD6D1C7),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Encabezado "Cerca de ti"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cerca de ti',
                            style: GoogleFonts.rubik(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            '${_filteredSpots.length} puestos en SLP',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Lista horizontal visible en estado replegado (18%)
                      SizedBox(
                        height: 78,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filteredSpots.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final spot = _filteredSpots[index];
                            final isSelected = _selectedSpot?.id == spot.id;

                            return _buildSpotHorizontalCard(
                              spot: spot,
                              isSelected: isSelected,
                              isDark: isDark,
                              surfaceColor: surfaceColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              primaryColor: primaryColor,
                              onTap: () => _onSpotSelected(spot),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Lista vertical extendida al deslizar hacia arriba
                      Text(
                        'Puestos en San Luis Potosí (Col. Popular y Zona U)',
                        style: GoogleFonts.rubik(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),

                      const SizedBox(height: 12),

                      ..._filteredSpots.map((spot) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildSpotVerticalCard(
                            spot: spot,
                            isDark: isDark,
                            surfaceColor: surfaceColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            primaryColor: primaryColor,
                            onTap: () => _onSpotSelected(spot),
                          ),
                        );
                      }),

                      const SizedBox(height: 30),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Chip individual de categoría con estilo cápsula
  Widget _buildCategoryFilterChip({
    required String label,
    required MarketCategory category,
    required bool isSelected,
    required Color primaryColor,
    required Color surfaceColor,
    required Color textPrimary,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? const Color(0xFF38342F) : const Color(0xFFEBE6DC)),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? primaryColor.withAlpha(70)
                  : Colors.black.withAlpha(isDark ? 40 : 12),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: isSelected ? Colors.white : textPrimary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// Botón flotante para alternar tema
  Widget _buildFloatingThemeButton(bool isDark, Color surfaceColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ThemeController.instance.toggleTheme(),
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF22201D) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              if (isDark)
                BoxShadow(
                  color: const Color(0xFFFFB300).withAlpha(60),
                  blurRadius: 14,
                  spreadRadius: 2,
                )
              else
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFF38342F) : const Color(0xFFEBE6DC),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 22,
              color: isDark ? const Color(0xFFFFB300) : const Color(0xFF1E293B),
            )
                .animate(key: ValueKey<bool>(isDark))
                .scale(duration: 250.ms, curve: Curves.easeOutBack)
                .rotate(duration: 350.ms, curve: Curves.easeOut),
          ),
        ),
      ),
    );
  }

  /// Tarjeta horizontal compacta para el DraggableScrollableSheet
  Widget _buildSpotHorizontalCard({
    required SpotItem spot,
    required bool isSelected,
    required bool isDark,
    required Color surfaceColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    final cardBg = isDark ? const Color(0xFF2D2A26) : const Color(0xFFF7F5F0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? const Color(0xFF38342F) : const Color(0xFFEBE6DC)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Miniatura con bordes redondeados
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 58,
                height: 58,
                child: spot.imageUrl != null && spot.imageUrl!.isNotEmpty
                    ? Image.network(
                        spot.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildItemFallbackIcon(spot, isDark),
                      )
                    : _buildItemFallbackIcon(spot, isDark),
              ),
            ),
            const SizedBox(width: 10),
            // Detalles del puesto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    spot.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.rubik(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        spot.type == SpotType.localBusiness ? '🏪' : '👗',
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${spot.category} • ${_formatExactDistance(spot)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    spot.formattedPrice,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tarjeta vertical para vista expandida
  Widget _buildSpotVerticalCard({
    required SpotItem spot,
    required bool isDark,
    required Color surfaceColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    final cardBg = isDark ? const Color(0xFF2D2A26) : const Color(0xFFF7F5F0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF38342F) : const Color(0xFFEBE6DC),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 64,
                height: 64,
                child: spot.imageUrl != null && spot.imageUrl!.isNotEmpty
                    ? Image.network(
                        spot.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildItemFallbackIcon(spot, isDark),
                      )
                    : _buildItemFallbackIcon(spot, isDark),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          spot.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.rubik(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: spot.isOpen
                              ? Colors.green.withAlpha(25)
                              : Colors.red.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          spot.isOpen ? 'Abierto' : 'Cerrado',
                          style: TextStyle(
                            color: spot.isOpen ? Colors.green : Colors.red,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${spot.category} • ${_formatExactDistance(spot)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spot.formattedPrice,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemFallbackIcon(SpotItem spot, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF3A3631) : const Color(0xFFE5E0D8),
      child: Center(
        child: Text(
          spot.category.toLowerCase().contains('bazar') || spot.type == SpotType.reseller
              ? '👗'
              : (spot.title.toLowerCase().contains('elote') ? '🌽' : '🍧'),
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

/// Marcador estilizado en forma de gota invertida (Teardrop Pin)
class _SpotTeardropMarker extends StatelessWidget {
  final Color pinColor;
  final String category;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpotTeardropMarker({
    required this.pinColor,
    required this.category,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double width = isSelected ? 48 : 42;
    final double height = isSelected ? 58 : 52;
    final double innerCircle = isSelected ? 26 : 22;

    Widget iconContent;
    final lowerTitle = title.toLowerCase();
    final lowerCategory = category.toLowerCase();

    if (lowerCategory.contains('bazar') || lowerCategory.contains('segunda')) {
      iconContent = Image.asset(
        'assets/images/logo.png',
        width: isSelected ? 18 : 15,
        height: isSelected ? 18 : 15,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.checkroom_rounded,
          size: isSelected ? 16 : 13,
          color: pinColor,
        ),
      );
    } else if (lowerTitle.contains('elote') || lowerTitle.contains('esquite')) {
      iconContent = Text(
        '🌽',
        style: TextStyle(fontSize: isSelected ? 14 : 12),
      );
    } else if (lowerTitle.contains('torta') || lowerTitle.contains('gordita')) {
      iconContent = Text(
        '🌮',
        style: TextStyle(fontSize: isSelected ? 14 : 12),
      );
    } else {
      iconContent = Text(
        '🍧',
        style: TextStyle(fontSize: isSelected ? 14 : 12),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            CustomPaint(
              size: Size(width, height),
              painter: _TeardropPinPainter(color: pinColor),
            ),
            Positioned(
              top: isSelected ? 5.5 : 4.5,
              child: Container(
                width: innerCircle,
                height: innerCircle,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(child: iconContent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter para dibujar la silueta suave de la gota/pin
class _TeardropPinPainter extends CustomPainter {
  final Color color;

  const _TeardropPinPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;

    final path = Path();
    path.moveTo(w / 2, h);
    path.cubicTo(w * 0.12, h * 0.65, 0, r * 1.35, 0, r);
    path.arcTo(
      Rect.fromLTWH(0, 0, w, w),
      3.14159265,
      3.14159265,
      false,
    );
    path.cubicTo(w, r * 1.35, w * 0.88, h * 0.65, w / 2, h);
    path.close();

    // Sombra del marcador
    canvas.drawShadow(path, Colors.black.withAlpha(70), 4, true);

    // Cuerpo del marcador
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TeardropPinPainter oldDelegate) => oldDelegate.color != color;
}

/// Marcador GPS animado con halo de precisión suave y gestión limpia de AnimationController
class _UserGpsMarker extends StatefulWidget {
  const _UserGpsMarker();

  @override
  State<_UserGpsMarker> createState() => _UserGpsMarkerState();
}

class _UserGpsMarkerState extends State<_UserGpsMarker> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo de precisión translúcido
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2196F3).withAlpha(45),
              ),
            ),
          ),
          // Punto GPS central con aro blanco nítido
          Container(
            width: 17,
            height: 17,
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E88E5).withAlpha(140),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
