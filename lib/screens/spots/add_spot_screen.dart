import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../services/spot_service.dart';

/// Tipos de venta seleccionables en el formulario
enum SaleType { bazar, food, reseller }

/// Pantalla para registrar y publicar un nuevo punto o bazar en el mapa
class AddSpotScreen extends StatefulWidget {
  final LatLng? initialLocation;

  /// Hook para pruebas unitarias: inyecta archivos iniciales sin requerir image_picker nativo
  @visibleForTesting
  static List<XFile>? mockInitialFiles;

  /// Hook para pruebas unitarias: simula selección de archivos desde la galería
  @visibleForTesting
  static Future<List<XFile>> Function()? mockPickImages;

  const AddSpotScreen({
    super.key,
    this.initialLocation,
  });

  @override
  State<AddSpotScreen> createState() => _AddSpotScreenState();
}

class _AddSpotScreenState extends State<AddSpotScreen> {
  final _formKey = GlobalKey<FormState>();

  // Estado de carga durante la persistencia en Supabase
  bool _isPublishing = false;

  // Tipo de venta activo (por defecto Reventa como en la captura de modo claro)
  SaleType _selectedType = SaleType.reseller;

  // Controladores de texto
  final TextEditingController _meetingPointsController = TextEditingController();
  final TextEditingController _exactAddressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _deliveryCostController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // Configuración especial para Puesto de comida
  bool _hasDelivery = false;

  // Ubicación seleccionada en el mapa interactivo
  late LatLng _selectedLocation;

  // Controlador del mapa interactivo miniatura
  final MapController _miniMapController = MapController();

  // Selector de imágenes de la galería del dispositivo
  final ImagePicker _imagePicker = ImagePicker();

  // Lista de archivos de fotos seleccionadas (máximo 5)
  final List<XFile> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    // Centra en la ubicación recibida o en Colonia Popular / San Luis Potosí
    _selectedLocation = widget.initialLocation ?? const LatLng(22.1630, -100.9605);

    // Inyección de archivos para pruebas unitarias si aplica
    if (AddSpotScreen.mockInitialFiles != null) {
      _selectedFiles.addAll(AddSpotScreen.mockInitialFiles!);
    }
  }

  @override
  void dispose() {
    _miniMapController.dispose();
    _meetingPointsController.dispose();
    _exactAddressController.dispose();
    _descriptionController.dispose();
    _deliveryCostController.dispose();
    _priceController.dispose();
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

  /// Abre la galería para seleccionar una o varias imágenes locales
  Future<void> _pickImages() async {
    if (_selectedFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Has alcanzado el límite máximo de 5 fotos.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      if (AddSpotScreen.mockPickImages != null) {
        final mockPicked = await AddSpotScreen.mockPickImages!();
        if (mockPicked.isNotEmpty) {
          setState(() {
            final remaining = 5 - _selectedFiles.length;
            _selectedFiles.addAll(mockPicked.take(remaining));
          });
        }
        return;
      }

      final remainingSlots = 5 - _selectedFiles.length;
      final pickedList = await _imagePicker.pickMultiImage(
        limit: remainingSlots,
        imageQuality: 85,
      );

      if (pickedList.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(pickedList.take(remainingSlots));
        });
      }
    } catch (e) {
      debugPrint('Error al seleccionar imágenes múltiples: $e');
      // Intentar fallback a selección individual si pickMultiImage no estuviera disponible
      try {
        final single = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (single != null) {
          setState(() {
            _selectedFiles.add(single);
          });
        }
      } catch (inner) {
        debugPrint('Error en fallback de imagen: $inner');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudieron seleccionar fotos: $inner'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  /// Valida los datos y persiste el punto junto con sus fotos en Supabase
  Future<void> _publishSpot() async {
    if (_isPublishing) return;

    final isReseller = _selectedType == SaleType.reseller;

    // 1. Validación de coordenadas válidas
    if (_selectedLocation.latitude == 0 && _selectedLocation.longitude == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor selecciona una ubicación válida sobre el mapa.'),
          backgroundColor: AppColors.lightPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // 2. Validación de al menos una fotografía seleccionada
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor agrega al menos una foto de tu producto o puesto.'),
          backgroundColor: AppColors.lightPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // 3. Validaciones según el tipo seleccionado
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

    // 4. Extraer o componer título amigable
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

    // 5. Resolver categoría y tipo
    final String category = _selectedType == SaleType.food
        ? 'Antojitos'
        : (_selectedType == SaleType.bazar ? 'Bazar' : 'Segunda mano');

    final String tipoStr = _selectedType == SaleType.food
        ? 'comida'
        : (_selectedType == SaleType.bazar ? 'bazar' : 'reventa');

    setState(() {
      _isPublishing = true;
    });

    try {
      // Paso A: Subir archivos de imágenes a Supabase Storage (bucket 'spots-media')
      final uploadedUrls = await SpotService.subirImagenesStorage(_selectedFiles);

      // Extraer precio especificado por el usuario o usar 40.0 como valor base
      final priceClean = _priceController.text.trim().replaceAll('\$', '').replaceAll(',', '');
      final double resolvedPrice = double.tryParse(priceClean) ?? 40.0;

      // Paso B: Publicar en la base de datos Supabase (Spot, Detalle y Foto_spot)
      final createdSpot = await SpotService.publicarSpot(
        titulo: title,
        precio: resolvedPrice,
        latitud: _selectedLocation.latitude,
        longitud: _selectedLocation.longitude,
        tipo: tipoStr,
        categoriaNombre: category,
        descripcion: _descriptionController.text.trim(),
        direccionExacta: !isReseller ? _exactAddressController.text.trim() : null,
        tieneEnvio: _selectedType == SaleType.food ? _hasDelivery : null,
        costoEnvio: (_selectedType == SaleType.food && _hasDelivery)
            ? _deliveryCostController.text.trim()
            : null,
        horario: _selectedType == SaleType.bazar ? '10:00 - 18:00' : null,
        radioAprox: 300.0,
        zonaReferencia: isReseller ? _meetingPointsController.text.trim() : null,
        fotosUrls: uploadedUrls,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡Punto publicado exitosamente en el mapa!'),
          backgroundColor: const Color(0xFF1B7F4B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.pop(context, createdSpot);
    } on PostgrestException catch (e) {
      debugPrint('Error de PostgREST al publicar spot: ${e.message} (código: ${e.code})');
      if (!mounted) return;
      setState(() {
        _isPublishing = false;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al publicar: ${e.message}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      debugPrint('Error al publicar spot en Supabase: $e');
      if (!mounted) return;
      setState(() {
        _isPublishing = false;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al publicar: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
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

                        // Selector interactivo de mapa con círculo de zona (~300m)
                        _buildInteractiveMapSelector(
                          isDark: isDark,
                          isReseller: true,
                          activeColor: activeColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
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

                        // Selector interactivo de mapa con pin exacto
                        _buildInteractiveMapSelector(
                          isDark: isDark,
                          isReseller: false,
                          activeColor: activeColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
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

                      // --- 4. PRECIO ESTIMADO ---
                      Row(
                        children: [
                          Text(
                            'Precio (MXN)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(opcional)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildCustomTextField(
                        controller: _priceController,
                        hintText: 'ej. 45 o 120',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icon(
                          Icons.attach_money_rounded,
                          color: activeColor,
                          size: 20,
                        ),
                        inputBg: inputBg,
                        borderColor: borderColor,
                        activeColor: activeColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      const SizedBox(height: 22),

                      // --- 5. SELECCIÓN DE FOTOS (IMAGE_PICKER / MÁX. 5) ---
                      _buildPhotoSelectionSection(
                        isDark: isDark,
                        surfaceBg: surfaceBg,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        activeColor: activeColor,
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
                  onPressed: _isPublishing ? null : _publishSpot,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    disabledBackgroundColor: primaryColor.withAlpha(160),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _isPublishing
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
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
        return const SizedBox(
          width: 34,
          height: 34,
          child: Center(
            child: Text(
              '🌮',
              style: TextStyle(fontSize: 24),
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
    TextInputType? keyboardType,
    Widget? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
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

  /// Selector interactivo de ubicación sobre el mapa con flutter_map
  Widget _buildInteractiveMapSelector({
    required bool isDark,
    required bool isReseller,
    required Color activeColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF38342F) : const Color(0xFFE0DCD5),
                width: 1.2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Mapa interactivo con soporte para arrastre y tap to place
                FlutterMap(
                  mapController: _miniMapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: 15.5,
                    minZoom: 11.0,
                    maxZoom: 18.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                    ),
                    onTap: (tapPosition, point) {
                      setState(() {
                        _selectedLocation = point;
                      });
                      _miniMapController.move(point, _miniMapController.camera.zoom);
                    },
                    onPositionChanged: (camera, hasGesture) {
                      if (hasGesture) {
                        setState(() {
                          _selectedLocation = camera.center;
                        });
                      }
                    },
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

                    // Círculo translúcido de ~300m para reventa
                    if (isReseller)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _selectedLocation,
                            radius: 300,
                            useRadiusInMeter: true,
                            color: activeColor.withAlpha(isDark ? 45 : 30),
                            borderColor: activeColor.withAlpha(isDark ? 180 : 160),
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),

                    // Marcador central en el punto seleccionado
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation,
                          width: 44,
                          height: 44,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: activeColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: activeColor.withAlpha(120),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isReseller
                                      ? Icons.handshake_rounded
                                      : (_selectedType == SaleType.food
                                          ? Icons.restaurant_rounded
                                          : Icons.storefront_rounded),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Chip superior de guía interactiva
                Positioned(
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xCC1A1816) : const Color(0xEEFFFFFF),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? const Color(0xFF38342F) : const Color(0xFFE5E0D8),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 13,
                          color: activeColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isReseller
                              ? 'Zona aproximada (toca o arrastra)'
                              : 'Toca o arrastra para ubicar el punto',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Etiqueta flotante de zona / colonia en el centro para Reventa
                if (isReseller)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
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
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ),

                // Botón flotante para recentrar ubicación
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Material(
                    color: isDark ? const Color(0xFF262421) : Colors.white,
                    elevation: 3,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        final target = widget.initialLocation ?? const LatLng(22.1630, -100.9605);
                        _miniMapController.move(target, 15.5);
                        setState(() {
                          _selectedLocation = target;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(9),
                        child: Icon(
                          Icons.my_location_rounded,
                          size: 20,
                          color: activeColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Coordenadas actuales capturadas
        Row(
          children: [
            Icon(
              Icons.pin_drop_rounded,
              size: 14,
              color: textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              'Coordenadas: Lat ${_selectedLocation.latitude.toStringAsFixed(4)}, Lng ${_selectedLocation.longitude.toStringAsFixed(4)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Selector horizontal de fotos locales del dispositivo (image_picker)
  Widget _buildPhotoSelectionSection({
    required bool isDark,
    required Color surfaceBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color activeColor,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fotos del producto / puesto',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              Text(
                '${_selectedFiles.length} / 5',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 88,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                // Botón de tarjeta punteada/icono '+' para "Agregar fotos" desde la galería
                if (_selectedFiles.length < 5)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      onTap: _pickImages,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 84,
                        height: 86,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2D2A26) : const Color(0xFFF7F5F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: activeColor.withAlpha(isDark ? 140 : 100),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 22,
                              color: activeColor,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Agregar fotos\n(máx. 5)',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.0,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Miniaturas cuadradas redondeadas (80x80 px aprox.)
                ..._selectedFiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 80,
                            height: 86,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: index == 0
                                    ? activeColor
                                    : (isDark ? const Color(0xFF433E37) : const Color(0xFFE2DDD5)),
                                width: index == 0 ? 1.6 : 1.0,
                              ),
                            ),
                            child: _buildImageThumbnail(file, isDark),
                          ),
                        ),

                        // Badge distintivo "Portada" en la primera foto seleccionada (índice 0)
                        if (index == 0)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF05A24),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Portada',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),

                        // Botón de cruz/eliminar ('x') en cada miniatura para remover fotos individuales
                        Positioned(
                          top: -5,
                          right: -5,
                          child: GestureDetector(
                            onTap: () => _removePhoto(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD81B60),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 12,
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
                  (5 - _selectedFiles.length - (_selectedFiles.length < 5 ? 1 : 0)).clamp(0, 4),
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Container(
                      width: 76,
                      height: 86,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1C1A) : const Color(0xFFF9F7F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF33302B) : const Color(0xFFE8E4DC),
                          width: 1,
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
    );
  }

  /// Construye la vista previa de la imagen local según su ruta y plataforma
  Widget _buildImageThumbnail(XFile file, bool isDark) {
    if (kIsWeb ||
        file.path.startsWith('http://') ||
        file.path.startsWith('https://') ||
        file.path.startsWith('blob:')) {
      return Image.network(
        file.path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImageFallback(isDark),
      );
    }

    final ioFile = File(file.path);
    if (ioFile.existsSync()) {
      return Image.file(
        ioFile,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImageFallback(isDark),
      );
    }

    // Fallback para entornos de testing o rutas virtuales
    return _buildImageFallback(isDark);
  }

  Widget _buildImageFallback(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2D2A26) : const Color(0xFFF5EFEB),
      child: Center(
        child: Icon(
          Icons.image_rounded,
          size: 28,
          color: isDark ? const Color(0xFF8C827A) : const Color(0xFFB3A89F),
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
