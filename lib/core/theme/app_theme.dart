import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme);
    final headingTextTheme = GoogleFonts.rubikTextTheme(ThemeData.light().textTheme);

    final textTheme = baseTextTheme.copyWith(
      displayLarge: headingTextTheme.displayLarge?.copyWith(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: headingTextTheme.displayMedium?.copyWith(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: headingTextTheme.displaySmall?.copyWith(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: headingTextTheme.headlineLarge?.copyWith(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: headingTextTheme.headlineMedium?.copyWith(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: headingTextTheme.headlineSmall?.copyWith(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: headingTextTheme.titleLarge?.copyWith(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: headingTextTheme.titleMedium?.copyWith(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: headingTextTheme.titleSmall?.copyWith(
        color: AppColors.lightTextPrimary,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: AppColors.lightTextPrimary,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: AppColors.lightTextPrimary,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: AppColors.lightTextSecondary,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightScaffold,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightSecondary,
        tertiary: AppColors.lightTertiary,
        surface: AppColors.lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightScaffold,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.rubik(
          color: AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightInputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: AppColors.lightTextSecondary),
        hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.lightTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);
    final headingTextTheme = GoogleFonts.rubikTextTheme(ThemeData.dark().textTheme);

    final textTheme = baseTextTheme.copyWith(
      displayLarge: headingTextTheme.displayLarge?.copyWith(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: headingTextTheme.displayMedium?.copyWith(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: headingTextTheme.displaySmall?.copyWith(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: headingTextTheme.headlineLarge?.copyWith(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: headingTextTheme.headlineMedium?.copyWith(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: headingTextTheme.headlineSmall?.copyWith(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: headingTextTheme.titleLarge?.copyWith(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: headingTextTheme.titleMedium?.copyWith(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: headingTextTheme.titleSmall?.copyWith(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        color: AppColors.darkTextSecondary,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkScaffold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkSecondary,
        tertiary: AppColors.darkTertiary,
        surface: AppColors.darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.black,
        onSurface: AppColors.darkTextPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkScaffold,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.rubik(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkInputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: AppColors.darkTextSecondary),
        hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.darkTextSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}
