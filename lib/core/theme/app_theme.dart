import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ChronoCards App Theme
class AppTheme {
  AppTheme._();

  // Primary colors - Dark fantasy theme
  static const Color primaryDark = Color(0xFF1A1A2E);
  static const Color primaryMid = Color(0xFF16213E);
  static const Color primaryLight = Color(0xFF0F3460);
  
  // Accent colors - Gold/Cosmic theme
  static const Color accentGold = Color(0xFFE94560);
  static const Color accentCosmic = Color(0xFF533483);
  static const Color accentMystic = Color(0xFF9D4EDD);
  
  // UI Colors
  static const Color cardBackground = Color(0xFF252A34);
  static const Color cardBorder = Color(0xFF393E46);
  static const Color healthRed = Color(0xFFFF6B6B);
  static const Color manaBlue = Color(0xFF4ECDC4);
  static const Color energyYellow = Color(0xFFFFE66D);
  
  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textGold = Color(0xFFFFD700);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryDark,
      colorScheme: const ColorScheme.dark(
        primary: accentGold,
        secondary: accentCosmic,
        tertiary: accentMystic,
        surface: primaryMid,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.orbitronTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          displayMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 14,
            color: textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
      ),
      cardTheme: const CardTheme(
        color: cardBackground,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: cardBorder, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          foregroundColor: primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
