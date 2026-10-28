import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../core/theme/app_colors.dart';
import '../../models/spot_item.dart';

/// Tipos de venta seleccionables en el formulario
enum SaleType { bazar, food, reseller }

/// Pantalla para registrar y publicar un nuevo punto o bazar en el mapa
class AddSpotScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const AddSpotScreen({
    super.key,
    this.initialLocation,
  });

  @override
  State<AddSpotScreen> createState() => _AddSpotScreenState();
}

class _AddSpotScreenState extends State<AddSpotScreen> {
  final _formKey = GlobalKey<FormState>();

  // Tipo de venta activo (por defecto Reventa como en la captura de modo claro)
  SaleType _selectedType = SaleType.reseller;

  // Controladores de texto
  final TextEditingController _meetingPointsController = TextEditingController();
  final TextEditingController _exactAddressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _deliveryCostController = TextEditingController();

  // Configuración especial para Puesto de comida
  bool _hasDelivery = false;

  // Coordenada central del mapa miniatura
  late LatLng _mapCenter;

  // Fotos seleccionadas (máximo 5)
  final List<String> _photos = [];

  // Banco de imágenes de muestra para demostración rápida al pulsar la cámara
  final List<String> _sampleImages = const [
    'https://images.unsplash.com/photo-1551782450-a2132b4ba21d?w=300&q=80',
    'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=300&q=80',
    'https://images.unsplash.com/photo-1501443762994-82bd5dace89a?w=300&q=80',
    'https://images.unsplash.com/photo-1588702547923-7093a6c3ba33?w=300&q=80',
    'https://images.unsplash.com/photo-1539185441755-769473a23570?w=300&q=80',
  ];

  @override
  void initState() {
    super.initState();
    // Centra en la ubicación recibida o en Colonia Popular / San Luis Potosí
    _mapCenter = widget.initialLocation ?? const LatLng(22.1630, -100.9605);
  }

  @override
  void dispose() {
    _meetingPointsController.dispose();
    _exactAddressController.dispose();
    _descriptionController.dispose();
    _deliveryCostController.dispose();
    super.dispose();
  }

  Color _getAccentColor(SaleType type, bool isDark) {
    switch (type) {
      case SaleType.bazar:
        return isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
      case SaleType.food:
        return isDark ? AppColors.darkTertiary : AppColors.lightTertiary;
      case SaleType.reseller:
        return isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    }
  }

  Color _getActiveCardBg(SaleType type, bool isDark) {
    final baseColor = _getAccentColor(type, isDark);
    return baseColor.withAlpha(isDark ? 36 : 22);
  }

  void _addPhoto() {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Has alcanzado el límite máximo de 5 fotos.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _photos.add(_sampleImages[_photos.length % _sampleImages.length]);
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _publishSpot() {
    final isReseller = _selectedType == SaleType.reseller;

    // 1. Validaciones según el tipo seleccionado
    if (isReseller && _meetingPointsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor indica los puntos de entrega o puntos medios.'),
          backgroundColor: AppColors.lightPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (!isReseller && _exactAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor indica la dirección exacta del puesto o local.'),
          backgroundColor: AppColors.lightPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor ingresa una breve descripción de lo que ofreces.'),
          backgroundColor: AppColors.lightPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // 2. Extraer o componer título amigable
    String title = _descriptionController.text.trim();
    if (title.contains('\n')) {
      title = title.split('\n').first.trim();
    }
    if (title.length > 60) {
      title = '${title.substring(0, 57)}...';
    }
    if (title.isEmpty) {
      title = _selectedType == SaleType.food
          ? 'Puesto de comida'
          : (_selectedType == SaleType.bazar ? 'Bazar de colonia' : 'Reventa de artículos');
    }

    // 3. Resolver categoría y tipo
    final String category = _selectedType == SaleType.food
        ? 'Antojitos'
        : (_selectedType == SaleType.bazar ? 'Bazar' : 'Segunda mano');

    final SpotType spotType = isReseller ? SpotType.reseller : SpotType.localBusiness;

    // 4. Imagen principal
    final String imageUrl = _photos.isNotEmpty
        ? _photos.first
        : (_selectedType == SaleType.food
            ? 'https://images.unsplash.com/photo-1551782450-a2132b4ba21d?w=300&q=80'
            : (_selectedType == SaleType.bazar
                ? 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=300&q=80'
                : 'https://images.unsplash.com/photo-1588702547923-7093a6c3ba33?w=300&q=80'));

    // 5. Instanciar SpotItem
    final newSpot = SpotItem(
      id: 'spot_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      price: 40.0,
      type: spotType,
      category: category,
      distance: 'a 50 m',
      exactAddress: !isReseller ? _exactAddressController.text.trim() : null,
      meetingPoints: isReseller
          ? _meetingPointsController.text
              .trim()
              .split(',')
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList()
          : null,
      imageUrl: imageUrl,
      position: _mapCenter,
      description: _descriptionController.text.trim(),
      isOpen: true,
      hasDelivery: _hasDelivery,
      deliveryCost: _hasDelivery && _deliveryCostController.text.trim().isNotEmpty
          ? _deliveryCostController.text.trim()
          : null,
    );

    Navigator.pop(context, newSpot);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.lightScaffold;
    final surfaceBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final inputBg = isDark ? AppColors.darkInputBackground : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final activeColor = _getAccentColor(_selectedType, isDark);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Agregar punto al mapa',
          style: GoogleFonts.rubik(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 1. TIPO DE VENTA ---
                      Text(
                        'Tipo de venta',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSaleTypeCard(
                              type: SaleType.bazar,
                              title: 'Bazar',
                              isSelected: _selectedType == SaleType.bazar,
                              isDark: isDark,
                              surfaceBg: surfaceBg,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildSaleTypeCard(
                              type: SaleType.food,
                              title: 'Puesto de\ncomida',
                              isSelected: _selectedType == SaleType.food,
                              isDark: isDark,
                              surfaceBg: surfaceBg,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildSaleTypeCard(
                              type: SaleType.reseller,
                              title: 'Reventa',
                              isSelected: _selectedType == SaleType.reseller,
                              isDark: isDark,
                              surfaceBg: surfaceBg,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // --- 2. CAMPOS DINÁMICOS SEGÚN TIPO ---
                      if (_selectedType == SaleType.reseller) ...[
                        // Sección Reventa: Puntos de entrega
                        Text(
                          'Puntos de entrega (puntos medios)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildCustomTextField(
                          controller: _meetingPointsController,
                          hintText: 'Ingresa puntos medios (ej. OXXO Glorieta, Kiosco)',
                          inputBg: inputBg,
                          borderColor: borderColor,
                          activeColor: activeColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),

                        const SizedBox(height: 14),

                        // Miniatura de mapa con círculo translúcido (~300m)
                        _buildMiniMapPreview(
                          isDark: isDark,
                          isReseller: true,
                          activeColor: activeColor,
                          textPrimary: textPrimary,
                        ),

                        const SizedBox(height: 12),

                        // Cuadro informativo de seguridad amarillo
                        _buildSecurityAlertBanner(isDark),
                      ] else ...[
                        // Sección Bazar o Puesto de comida: Dirección exacta
                        Text(
                          'Ubicación',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dirección exacta del local o puesto',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildCustomTextField(
                          controller: _exactAddressController,
                          hintText: 'ej. Calle Morelos #105, frente a la tienda',
                          inputBg: inputBg,
                          borderColor: borderColor,
                          activeColor: activeColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),

                        const SizedBox(height: 14),

                        // Miniatura de mapa con pin exacto
                        _buildMiniMapPreview(
                          isDark: isDark,
                          isReseller: false,
                          activeColor: activeColor,
                          textPrimary: textPrimary,
                        ),

                        // Sección adicional para Puesto de comida: Configuración especial
                        if (_selectedType == SaleType.food) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Configuración especial',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildFoodDeliverySection(
                            isDark: isDark,
                            surfaceBg: surfaceBg,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            activeColor: activeColor,
                            inputBg: inputBg,
                          ),
                        ],
                      ],

                      const SizedBox(height: 22),

                      // --- 3. DESCRIPCIÓN ---
                      Text(
                        'Descripción',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCustomTextField(
                        controller: _descriptionController,
                        hintText: isDark ? 'Descripción' : '¿Qué vendes o ofreces?',
                        maxLines: 3,
                        inputBg: inputBg,
                        borderColor: borderColor,
                        activeColor: activeColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      const SizedBox(height: 22),

                      // --- 4. AGREGAR FOTOS (MÁX. 5) ---
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: surfaceBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 84,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  // Botón inicial de agregar cámara
                                  InkWell(
                                    onTap: _addPhoto,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 90,
                                      height: 84,
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF2D2A26) : const Color(0xFFF7F5F0),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF433E37) : const Color(0xFFE2DDD5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.camera_alt_outlined,
                                            size: 24,
                                            color: textPrimary,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Agregar fotos\n(máx. 5)',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w600,
                                              color: textSecondary,
                                              height: 1.1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // Previsualizaciones de fotos agregadas
                                  ..._photos.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final url = entry.value;

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: SizedBox(
                                              width: 72,
                                              height: 84,
                                              child: Image.network(
                                                url,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  color: isDark ? const Color(0xFF2D2A26) : const Color(0xFFF7F5F0),
                                                  child: Icon(Icons.image_outlined, color: textSecondary),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: -6,
                                            right: -6,
                                            child: GestureDetector(
                                              onTap: () => _removePhoto(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(3),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFD81B60),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close_rounded,
                                                  color: Colors.white,
                                                  size: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),

                                  // Ranuras de reserva vacías (para completar hasta 5)
                                  ...List.generate(
                                    (4 - _photos.length).clamp(0, 4),
                                    (i) => Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: Container(
                                        width: 72,
                                        height: 84,
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E1C1A) : const Color(0xFFF9F7F3),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF33302B) : const Color(0xFFE8E4DC),
                                            width: 1,
                                            strokeAlign: BorderSide.strokeAlignCenter,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.image_outlined,
                                            size: 22,
                                            color: textSecondary.withAlpha(90),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),

            // --- 5. BOTÓN DE PUBLICACIÓN FIJO INFERIOR ---
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: BoxDecoration(
                color: scaffoldBg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 50 : 15),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _publishSpot,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    'Publicar en el mapa',
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tarjeta individual del selector de tipo de venta
  Widget _buildSaleTypeCard({
    required SaleType type,
    required String title,
    required bool isSelected,
    required bool isDark,
    required Color surfaceBg,
    required Color borderColor,
    required Color textPrimary,
  }) {
    final accentColor = _getAccentColor(type, isDark);
    final cardBg = isSelected ? _getActiveCardBg(type, isDark) : surfaceBg;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 104,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : borderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withAlpha(isDark ? 50 : 30),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTypeIcon(type, isSelected ? accentColor : (isDark ? Colors.white70 : Colors.black87)),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? accentColor : textPrimary,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Icono estilizado según el tipo de venta
  Widget _buildTypeIcon(SaleType type, Color color) {
    switch (type) {
      case SaleType.bazar:
        return SizedBox(
          width: 34,
          height: 34,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 0,
                child: Icon(Icons.checkroom_rounded, size: 20, color: color),
              ),
              Positioned(
                bottom: 1,
                child: Icon(Icons.inventory_2_outlined, size: 22, color: color),
              ),
            ],
          ),
        );
      case SaleType.food:
        return SizedBox(
          width: 34,
          height: 34,
          child: Center(
            child: Text(
              '🌮',
              style: const TextStyle(fontSize: 24),
            ),
          ),
        );
      case SaleType.reseller:
        return SizedBox(
          width: 34,
          height: 34,
          child: Center(
            child: Icon(Icons.handshake_rounded, size: 28, color: color),
          ),
        );
    }
  }

  /// Campo de texto genérico con bordes redondeados y estilo cápsula
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required Color inputBg,
    required Color borderColor,
    required Color activeColor,
    required Color textPrimary,
    required Color textSecondary,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          color: textSecondary.withAlpha(160),
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: activeColor, width: 1.6),
        ),
      ),
    );
  }

  /// Miniatura de mapa integrada para visualización de zona o pin exacto
  Widget _buildMiniMapPreview({
    required bool isDark,
    required bool isReseller,
    required Color activeColor,
    required Color textPrimary,
  }) {
    const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF38342F) : const Color(0xFFE0DCD5),
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _mapCenter,
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: tileUrl,
                  userAgentPackageName: 'com.spotmarket.app',
                  tileBuilder: isDark
                      ? (context, tileWidget, tile) {
                          return ColorFiltered(
                            colorFilter: const ColorFilter.matrix(<double>[
                              -0.80, 0, 0, 0, 240,
                              0, -0.80, 0, 0, 235,
                              0, 0, -0.80, 0, 225,
                              0, 0, 0, 1, 0,
                            ]),
                            child: tileWidget,
                          );
                        }
                      : null,
                ),
                if (isReseller)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _mapCenter,
                        radius: 54, // Representación visual de 300m
                        useRadiusInMeter: false,
                        color: Colors.black.withAlpha(isDark ? 55 : 35),
                        borderColor: isDark ? Colors.white70 : Colors.black87,
                        borderStrokeWidth: 1.6,
                      ),
                    ],
                  )
                else
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _mapCenter,
                        width: 38,
                        height: 38,
                        child: Icon(
                          Icons.location_on_rounded,
                          color: activeColor,
                          size: 38,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Etiqueta de la colonia en el centro para Reventa
            if (isReseller)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xDD141311) : const Color(0xEEFFFFFF),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Colonia Popular',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Cuadro informativo de seguridad para el caso de Reventa
  Widget _buildSecurityAlertBanner(bool isDark) {
    final bgColor = isDark ? const Color(0xFF2C2415) : const Color(0xFFFEF8E7);
    final borderColor = isDark ? const Color(0xFF59431D) : const Color(0xFFFDE8B3);
    final iconColor = isDark ? const Color(0xFFFFB300) : const Color(0xFFD97706);
    final textColor = isDark ? const Color(0xFFFFD54F) : const Color(0xFF92400E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Por seguridad, no mostramos tu ubicación exacta, sólo una zona aproximada (300m)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sección de configuración especial exclusiva para Puesto de comida
  Widget _buildFoodDeliverySection({
    required bool isDark,
    required Color surfaceBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color activeColor,
    required Color inputBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Tiene envíos / a domicilio?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Costo del (opcional)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _hasDelivery,
                activeThumbColor: activeColor,
                activeTrackColor: activeColor.withAlpha(120),
                onChanged: (val) {
                  setState(() {
                    _hasDelivery = val;
                  });
                },
              ),
            ],
          ),
          if (_hasDelivery) ...[
            const SizedBox(height: 12),
            _buildCustomTextField(
              controller: _deliveryCostController,
              hintText: 'ej. \$20 en la colonia / Sin costo desde \$150',
              inputBg: inputBg,
              borderColor: borderColor,
              activeColor: activeColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}
