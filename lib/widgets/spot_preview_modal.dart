import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../models/spot_item.dart';

/// Modal flotante inferior para previsualizar la información de un puesto o artículo
/// cuando el usuario pulsa un marcador en el mapa.
class SpotPreviewModal extends StatelessWidget {
  final SpotItem spot;
  final VoidCallback? onClose;

  const SpotPreviewModal({
    super.key,
    required this.spot,
    this.onClose,
  });

  /// Método de utilidad para desplegar este modal como un ModalBottomSheet nativo
  static Future<void> show(BuildContext context, SpotItem spot) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SpotPreviewModal(spot: spot),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor = isDark ? AppColors.darkSurface : const Color(0xFFFFFFFF);
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final greenColor = isDark ? const Color(0xFF3DD598) : const Color(0xFF1B7F4B);
    final pinkColor = isDark ? const Color(0xFFFF5288) : const Color(0xFFD81B60);
    final cardBorderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isDark
            ? Border(top: BorderSide(color: cardBorderColor, width: 1))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 90 : 25),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle centrado
            Center(
              child: Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF4A4640) : const Color(0xFFD6D1C7),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Fila superior: Badge de tipo de puesto y distancia/cerrar
            Row(
              children: [
                _buildSpotTypeBadge(spot.type, isDark, greenColor, pinkColor),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.navigation_outlined,
                      size: 13,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      spot.distance,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                if (onClose != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2D2A26) : const Color(0xFFF0EBE1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, size: 16, color: textSecondary),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 14),

            // Fila principal: Foto miniatura + Título + Categoría + Precio
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Miniatura cuadrada redondeada
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 78,
                    height: 78,
                    color: isDark ? const Color(0xFF2D2A26) : const Color(0xFFF2ECE1),
                    child: spot.imageUrl != null && spot.imageUrl!.isNotEmpty
                        ? Image.network(
                            spot.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(spot, primaryColor, pinkColor),
                          )
                        : _buildFallbackThumbnail(spot, primaryColor, pinkColor),
                  ),
                ),

                const SizedBox(width: 14),

                // Textos informativos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Categoría
                      Text(
                        spot.category.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Título del puesto / artículo
                      Text(
                        spot.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.rubik(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Precio en naranja mandarina
                      Text(
                        spot.formattedPrice,
                        style: GoogleFonts.rubik(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Separador sutil
            Divider(
              color: isDark ? const Color(0xFF2E2B27) : const Color(0xFFEBE6DC),
              height: 1,
            ),

            const SizedBox(height: 14),

            // Sección condicional según SpotType
            if (spot.isLocalBusiness)
              _buildLocalBusinessSection(context, spot, textPrimary, textSecondary, greenColor)
            else
              _buildResellerSection(context, spot, textPrimary, textSecondary, primaryColor, isDark),
          ],
        ),
      ),
    );
  }

  /// Badge representativo del tipo de puesto
  Widget _buildSpotTypeBadge(SpotType type, bool isDark, Color greenColor, Color pinkColor) {
    final isLocal = type == SpotType.localBusiness;
    final badgeColor = isLocal ? greenColor : pinkColor;
    final label = isLocal ? 'Local / Puesto fijo' : 'Vendedor particular';
    final icon = isLocal ? Icons.storefront_rounded : Icons.person_pin_circle_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(isDark ? 35 : 22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor.withAlpha(isDark ? 90 : 70),
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: badgeColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Sección condicional para puestos fijos / locales
  Widget _buildLocalBusinessSection(
    BuildContext context,
    SpotItem spot,
    Color textPrimary,
    Color textSecondary,
    Color greenColor,
  ) {
    final address = spot.exactAddress ?? 'Dirección disponible en colonia';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.storefront, size: 19, color: greenColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                address,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Abriendo ruta hacia $address'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            icon: const Icon(Icons.navigation_rounded, size: 18),
            label: Text(
              'Cómo llegar',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: greenColor,
              foregroundColor: Colors.white,
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Sección condicional para vendedores particulares / revendedores
  Widget _buildResellerSection(
    BuildContext context,
    SpotItem spot,
    Color textPrimary,
    Color textSecondary,
    Color primaryColor,
    bool isDark,
  ) {
    final points = spot.meetingPoints ?? const ['OXXO Glorieta', 'Kiosco Plaza'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Puntos de entrega:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: points.map((point) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2A26) : const Color(0xFFF5F1E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF38342F) : const Color(0xFFE2DDD5),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 13,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    point,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(
                SnackBar(
                  content: const Text('Iniciando chat para acordar entrega'),
                  backgroundColor: primaryColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: Text(
              'Acordar punto de entrega',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Miniatura de reserva en caso de fallo o ausencia de imagen
  Widget _buildFallbackThumbnail(SpotItem spot, Color primaryColor, Color pinkColor) {
    final isBazar = spot.category.toLowerCase().contains('bazar') ||
        spot.category.toLowerCase().contains('ropa');

    return Center(
      child: isBazar
          ? Image.asset(
              'assets/images/logo.png',
              width: 34,
              height: 34,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.checkroom_rounded,
                size: 32,
                color: pinkColor,
              ),
            )
          : Icon(
              Icons.fastfood_rounded,
              size: 32,
              color: primaryColor,
            ),
    );
  }
}
