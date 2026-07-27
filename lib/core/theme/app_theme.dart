import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class AppTheme {
  static ThemeData get dark {
    final baseTextTheme = ThemeData.dark(useMaterial3: true).textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.tasks,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.tasks),
        ),
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.tasks,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(baseTextTheme).copyWith(
        bodyMedium: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: AppSizes.fontMd,
        ),
        bodySmall: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: AppSizes.fontSm,
        ),
        titleLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: AppSizes.fontXl,
          fontWeight: FontWeight.w600,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.tasks,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.tasks),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    );
  }
}
