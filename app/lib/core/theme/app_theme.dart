import 'package:flutter/material.dart';

/// Unified AppTheme for ChronoCards
/// All theme colors consolidated in one place
class AppTheme {
  // Primary colors
  static const Color primaryDark = Color(0xFF1A1A2E);
  static const Color primaryMid = Color(0xFF16213E);
  static const Color primaryLight = Color(0xFF0F3460);

  // Accent colors
  static const Color accentGold = Color(0xFFFFD700);
  static const Color accentCosmic = Color(0xFF533483);
  static const Color accentMystic = Color(0xFF9D4EDD);
  static const Color manaBlue = Color(0xFF4ECDC4);
  static const Color healthRed = Color(0xFFFF6B6B);
  static const Color energyYellow = Color(0xFFFFE66D);

  // Text colors
  static const Color textGold = Color(0xFFFFD700);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textPrimary = Color(0xFFE0E0E0);

  // UI colors
  static const Color cardBorder = Color(0xFF393E46);

  // Danger colors helper
  static Color getDangerColor(int level) {
    if (level <= 1) return manaBlue;
    if (level <= 2) return energyYellow;
    if (level <= 3) return const Color(0xFFFF9800);
    return healthRed;
  }

  // Location type colors
  static Color getLocationTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'city':
        return manaBlue;
      case 'town':
        return accentGold;
      case 'village':
        return const Color(0xFF8B4513);
      case 'wilderness':
        return const Color(0xFF228B22);
      case 'dungeon':
        return accentCosmic;
      case 'inn':
        return accentMystic;
      case 'special':
        return accentGold;
      default:
        return textSecondary;
    }
  }

  // Region colors
  static Color getRegionColor(String regionName) {
    switch (regionName.toLowerCase()) {
      case 'mingjiao':
      case '明教':
        return const Color(0xFFFF6B35);
      case 'shaolin':
      case '少林':
        return const Color(0xFFFFD700);
      case 'wudang':
      case '武当':
        return const Color(0xFF4ECDC4);
      case 'biaoju':
      case '镖局':
        return const Color(0xFF8B4513);
      case 'gaibang':
      case '丐帮':
        return const Color(0xFF9ACD32);
      case 'yewai':
      case '野外':
        return const Color(0xFF228B22);
      default:
        return const Color(0xFF666666);
    }
  }
}
