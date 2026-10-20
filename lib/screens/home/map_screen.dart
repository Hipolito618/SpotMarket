import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/theme_toggle_button.dart';

enum SpotCategory { todos, antojitos, bazares, segundaMano }

class SpotItem {
  final String id;
  final String title;
  final String categoryName;
  final SpotCategory category;
  final String description;
  final String distance;
  final LatLng position;
  final IconData icon;

  const SpotItem({
    required this.id,
    required this.title,
    required this.categoryName,
    required this.category,
    required this.description,
    required this.distance,
    required this.position,
    required this.icon,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  SpotCategory _selectedCategory = SpotCategory.todos;
  SpotItem? _selectedSpot;

  final LatLng _initialCenter = const LatLng(19.419444, -99.160556); // Colonia Roma / Condesa

  final List<SpotItem> _spots = const [
    SpotItem(
      id: '1',
      title: 'Tamales y Atole Doña Lucha',
      categoryName: 'Antojitos de Colonia',
      category: SpotCategory.antojitos,
      description: 'Tamales oaxaqueños, verdes y dulce con atole de guayaba calientito todas las mañanas.',
      distance: 'A 120 m',
      position: LatLng(19.420100, -99.161200),
      icon: Icons.fastfood_rounded,
    ),
    SpotItem(
      id: '2',
      title: 'Bazar Vintage & Vinilos',
      categoryName: 'Bazar de Fin de Semana',
      category: SpotCategory.bazares,
      description: 'Discos de vinil, ropa vintage de los 80s y 90s, cámaras análogas y lámparas restauradas.',
      distance: 'A 350 m',
      position: LatLng(19.418700, -99.159800),
      icon: Icons.storefront_rounded,
    ),
    SpotItem(
      id: '3',
      title: 'Taller & Venta Bicis Usadas',
      categoryName: 'Segunda Mano',
      category: SpotCategory.segundaMano,
      description: 'Bicicletas de segunda mano garantizadas, refacciones y trueque de accesorios de ciclismo.',
      distance: 'A 450 m',
      position: LatLng(19.421500, -99.158500),
      icon: Icons.pedal_bike_rounded,
    ),
    SpotItem(
      id: '4',
      title: 'Elotes y Esquites El Güero',
      categoryName: 'Antojitos de Colonia',
      category: SpotCategory.antojitos,
      description: 'Esquites con tuétano, chile del que pica y del que no pica, mayonesa artesanal.',
      distance: 'A 280 m',
      position: LatLng(19.417800, -99.162000),
      icon: Icons.local_fire_department_rounded,
    ),
    SpotItem(
      id: '5',
      title: 'Venta de Garaje: Libros y Plantas',
      categoryName: 'Bazar / Segunda Mano',
      category: SpotCategory.bazares,
      description: 'Novelas, libros de arte, macetas con suculentas y esquejes cultivados en la azotea.',
      distance: 'A 500 m',
      position: LatLng(19.422200, -99.162800),
      icon: Icons.auto_stories_rounded,
    ),
  ];

  List<SpotItem> get _filteredSpots {
    if (_selectedCategory == SpotCategory.todos) {
      return _spots;
    }
    return _spots.where((s) => s.category == _selectedCategory).toList();
  }

  Color _getMarkerColor(SpotCategory category, ColorScheme colorScheme) {
    switch (category) {
      case SpotCategory.antojitos:
        return colorScheme.primary; // Mandarina cempasúchil
      case SpotCategory.bazares:
        return colorScheme.secondary; // Rosa bugambilia
      case SpotCategory.segundaMano:
        return colorScheme.tertiary; // Verde nopal
      case SpotCategory.todos:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'spotMarket',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 13,
                  color: colorScheme.onSurface.withAlpha(180),
                ),
                const SizedBox(width: 4),
                Text(
                  'Col. Roma Norte · CDMX',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Mapa Interactivo OpenStreetMap con flutter_map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 15.2,
              onTap: (tapPosition, point) {
                if (_selectedSpot != null) {
                  setState(() => _selectedSpot = null);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.spotmarket.app',
                // Tinte suave cuando está en modo oscuro para armonizar con el tema
                tileBuilder: isDark
                    ? (context, tileWidget, tile) {
                        return ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            -0.85, 0, 0, 0, 255, // Red invertido y suavizado
                            0, -0.85, 0, 0, 255, // Green
                            0, 0, -0.85, 0, 255, // Blue
                            0, 0, 0, 1, 0,       // Alpha
                          ]),
                          child: tileWidget,
                        );
                      }
                    : null,
              ),
              MarkerLayer(
                markers: _filteredSpots.map((spot) {
                  final markerColor = _getMarkerColor(spot.category, colorScheme);
                  final isSelected = _selectedSpot?.id == spot.id;

                  return Marker(
                    point: spot.position,
                    width: isSelected ? 54 : 44,
                    height: isSelected ? 54 : 44,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedSpot = spot);
                        _mapController.move(spot.position, 16.0);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        decoration: BoxDecoration(
                          color: markerColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: isSelected ? 3.5 : 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: markerColor.withAlpha(isSelected ? 140 : 80),
                              blurRadius: isSelected ? 12 : 6,
                              spreadRadius: isSelected ? 3 : 1,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          spot.icon,
                          color: Colors.white,
                          size: isSelected ? 26 : 20,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Selector horizontal de categorías hiperlocales
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip(
                    label: 'Todos',
                    icon: Icons.grid_view_rounded,
                    category: SpotCategory.todos,
                    activeColor: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryChip(
                    label: 'Antojitos 🌽',
                    icon: Icons.fastfood_rounded,
                    category: SpotCategory.antojitos,
                    activeColor: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryChip(
                    label: 'Bazares 🎪',
                    icon: Icons.storefront_rounded,
                    category: SpotCategory.bazares,
                    activeColor: colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryChip(
                    label: 'Segunda Mano 👕',
                    icon: Icons.recycling_rounded,
                    category: SpotCategory.segundaMano,
                    activeColor: colorScheme.tertiary,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

          // Botones flotantes (Recentrar y Publicar spot)
          Positioned(
            right: 16,
            bottom: _selectedSpot != null ? 210 : 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'recenter_btn',
                  onPressed: () {
                    _mapController.move(_initialCenter, 15.2);
                  },
                  tooltip: 'Centrar en mi colonia',
                  backgroundColor: theme.cardTheme.color,
                  foregroundColor: colorScheme.onSurface,
                  child: const Icon(Icons.my_location_rounded),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'add_spot_btn',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('¡Pronto podrás publicar tu antojito o bazar!'),
                        backgroundColor: colorScheme.primary,
                      ),
                    );
                  },
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: const Text(
                    'Publicar Spot',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Tarjeta flotante de detalle del Spot seleccionado
          if (_selectedSpot != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Card(
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getMarkerColor(_selectedSpot!.category, colorScheme).withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _selectedSpot!.icon,
                              color: _getMarkerColor(_selectedSpot!.category, colorScheme),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedSpot!.title,
                                  style: theme.textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      _selectedSpot!.categoryName,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: _getMarkerColor(_selectedSpot!.category, colorScheme),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Text(' · '),
                                    Text(
                                      _selectedSpot!.distance,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => setState(() => _selectedSpot = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _selectedSpot!.description,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Navegando a ${_selectedSpot!.title}...'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.directions_walk_rounded, size: 18),
                              label: const Text('Cómo llegar'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(40),
                                backgroundColor: _getMarkerColor(_selectedSpot!.category, colorScheme),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Guardado en favoritos')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(44, 40),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Icon(Icons.bookmark_border_rounded, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.15, end: 0),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required SpotCategory category,
    required Color activeColor,
  }) {
    final isSelected = _selectedCategory == category;
    final theme = Theme.of(context);

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
      ),
      backgroundColor: theme.cardTheme.color,
      selectedColor: activeColor,
      elevation: isSelected ? 3 : 1,
      pressElevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? activeColor : theme.colorScheme.outline.withAlpha(40),
          width: 1,
        ),
      ),
      onSelected: (_) {
        setState(() {
          _selectedCategory = category;
        });
      },
    );
  }
}
