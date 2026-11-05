import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../models/spot_item.dart';

/// Menú de opciones que se abre al mantener presionado un puesto.
class SpotOptionsSheet {
  SpotOptionsSheet._();

  static Future<void> show(
      BuildContext context, {
        required SpotItem spot,
        required bool esFavorito,
        required VoidCallback onVerDetalle,
        required VoidCallback onAlternarFavorito,
        required VoidCallback onVerEnMapa,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        Widget opcion({
          required IconData icono,
          required String texto,
          required VoidCallback accion,
          Color? color,
        }) {
          return ListTile(
            leading: Icon(icono, color: color ?? textPrimary),
            title: Text(
              texto,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: color ?? textPrimary,
              ),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              accion();
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF4A4640)
                      : const Color(0xFFD6D1C7),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        spot.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.rubik(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      spot.formattedPrice,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              opcion(
                icono: Icons.open_in_new_rounded,
                texto: 'Ver detalle',
                accion: onVerDetalle,
              ),
              opcion(
                icono: esFavorito
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                texto: esFavorito ? 'Quitar de favoritos' : 'Agregar a favoritos',
                accion: onAlternarFavorito,
                color: primary,
              ),
              opcion(
                icono: Icons.place_outlined,
                texto: 'Ver en el mapa',
                accion: onVerEnMapa,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}