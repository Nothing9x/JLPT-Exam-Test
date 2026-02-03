import 'package:flutter/material.dart';

class AppColors {
  // ============== SAKURA THEME (Light) ==============
  // Primary Colors - Sakura Pink
  static const Color primary = Color(0xFFFF6B9D); // Vibrant Sakura Pink
  static const Color primaryDark = Color(0xFFDB2777); // Deep Pink for contrast
  static const Color primaryLight = Color(0xFFFF9ABF); // Light Pink

  // Background Colors
  static const Color backgroundLight =
      Color(0xFFFFF5F9); // Soft off-white with pink hint
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color cardBackgroundLight = Colors.white;

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF1E293B); // Slate 800
  static const Color textSecondaryLight = Color(0xFF94A3B8); // Slate 400

  // Border Colors
  static const Color borderLight = Color(0xFFF1F5F9); // Slate 100

  // Gradient Colors for Banner
  static const Color gradientStart = Color(0xFFFF9A9E); // Light pink
  static const Color gradientEnd = Color(0xFFFF5E99); // Deeper pink

  // Accent Colors
  static const Color accentGreen = Color(0xFFA3C76D); // Free badge green
  static const Color accentRed = Color(0xFFDC2626); // Hot badge red (rose-600)
  static const Color accentIndigo = Color(0xFF6366F1); // Indigo accent

  // Icon Background (Pink tint)
  static const Color iconBackgroundLight =
      Color(0xFFFFF0F3); // Pink-50 equivalent

  // Shadow Color
  static const Color shadowPink =
      Color(0x26FF69B4); // Pink shadow with 15% opacity

  // ============== DARK THEME ==============
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color backgroundDarkSecondary = Color(0xFF1E293B);
  static const Color cardBackgroundDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFE0E7FF);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155);

  // Dark theme primary (keep pink theme in dark mode too)
  static const Color primaryDarkTheme = Color(0xFFFF85AD);

  // ============== LEGACY COLORS (for backward compatibility) ==============
  static const Color sakuraPink = Color(0xFFFFEEF2);
  static const Color matchaGreen = Color(0xFFB7D6A3);
  static const Color matchaDark = Color(0xFF8DAF78);
  static const Color tealAccent =
      Color(0xFFFF6B9D); // Changed to pink for consistency
  static const Color mintLight = Color(0xFFFFF0F3);
  static const Color mintGradient = Color(0xFFFFE4EC);
  static const Color buttonDark = Color(0xFF1E293B);
}
