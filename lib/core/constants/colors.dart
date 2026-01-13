import 'package:flutter/material.dart';

class AppColors {
  // ========================================
  // ENTERPRISE FINTECH PALETTE
  // ========================================

  // PRIMARY BRAND COLORS - Trust & Professionalism
  static const Color primary = Color(0xFF4F46E5); // Indigo 600 - Dynamic yet serious
  static const Color primaryDark = Color(0xFF3730A3); // Indigo 800
  static const Color primaryLight = Color(0xFF818CF8); // Indigo 400
  static const Color accent = Color(0xFF8B5CF6); // Violet 500
  static const Color accentLight = Color(0xFFA78BFA); // Violet 400

  // BACKGROUNDS - "Slate" Scale
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure White
  static const Color lightSurfaceAlt = Color(0xFFF1F5F9); // Slate 100
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9); // Slate 100
  
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkSurfaceAlt = Color(0xFF334155); // Slate 700
  static const Color darkSurfaceVariant = Color(0xFF334155); 

  // TEXT & CONTENT
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF64748B); // Slate 500
  static const Color lightTextTertiary = Color(0xFF94A3B8); // Slate 400
  static const Color lightTextDisabled = Color(0xFFCBD5E1);

  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkTextTertiary = Color(0xFF64748B); // Slate 500
  static const Color darkTextDisabled = Color(0xFF475569);

  // BORDERS
  static const Color lightBorder = Color(0xFFE2E8F0); // Slate 200
  static const Color lightBorderLight = Color(0xFFF1F5F9); // Slate 100
  static const Color darkBorder = Color(0xFF334155); // Slate 700
  static const Color darkBorderLight = Color(0xFF1E293B);

  static const Color lightDivider = Color(0xFFE2E8F0);
  static const Color darkDivider = Color(0xFF334155);

  // SEMANTIC COLORS
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successDark = Color(0xFF059669);
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorDark = Color(0xFFB91C1C);
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color info = Color(0xFF3B82F6); // Blue 500

  // CHARTS & GRAPHS
  static const List<Color> chartColors = [
    Color(0xFF4F46E5), // Indigo
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFF6366F1), // Indigo Light
  ];

  // ========================================
  // DYNAMIC ACCESSORS
  // ========================================
  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBackground : lightBackground;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurface : lightSurface;

  static Color surfaceAlt(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurfaceAlt : lightSurfaceAlt;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary;
  
  static Color textTertiary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextTertiary : lightTextTertiary;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorder : lightBorder;

  static Color inputBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurfaceAlt : lightSurfaceAlt;

  // ========================================
  // COMPATIBILITY & LEGACY SUPPORT
  // ========================================
  static const Color white = Colors.white;
  
  static const Color grey50 = Color(0xFFF8FAFC);
  static const Color grey100 = lightSurfaceAlt;
  static const Color grey200 = lightBorder;
  static const Color grey300 = Color(0xFFCBD5E1);
  static const Color grey400 = Color(0xFF94A3B8);
  static const Color grey500 = Color(0xFF64748B);
  static const Color grey600 = lightTextSecondary;
  static const Color grey700 = Color(0xFF334155);
  static const Color grey800 = Color(0xFF1E293B);
  static const Color grey900 = lightTextPrimary;
  
  // Category Colors
  static const Color crypto = Color(0xFF8B5CF6);
  static const Color stock = Color(0xFF3B82F6);
  static const Color forex = Color(0xFF10B981);
  static const Color commodity = Color(0xFFF59E0B);
  static const Color etf = Color(0xFFEC4899);
  static const Color bond = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> shadowSm(BuildContext context) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    )
  ];

  static List<BoxShadow> shadowMd(BuildContext context) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    )
  ];
}
