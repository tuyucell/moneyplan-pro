import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invest_guide/core/constants/colors.dart';

class AppTheme {
  // ========================================
  // ENTERPRISE LIGHT THEME
  // ========================================
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Core Colors
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primaryDark,

      secondary: AppColors.accent,
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: AppColors.accentLight,
      onSecondaryContainer: AppColors.accent,

      tertiary: AppColors.commodity,
      onTertiary: Color(0xFFFFFFFF),

      error: AppColors.error,
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFEBEE),
      onErrorContainer: AppColors.error,

      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainerHighest: AppColors.lightSurfaceVariant,
      onSurfaceVariant: AppColors.lightTextSecondary,

      outline: AppColors.lightBorder,
      outlineVariant: AppColors.lightBorderLight,

      shadow: Color(0x1A000000),
      scrim: Color(0x80000000),

      inverseSurface: AppColors.darkSurface,
      onInverseSurface: AppColors.darkTextPrimary,
      inversePrimary: AppColors.primaryLight,
    ),

    scaffoldBackgroundColor: AppColors.lightBackground,

    // AppBar with blur effect
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightSurface.withValues(alpha: 0.95),
      foregroundColor: AppColors.lightTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      titleTextStyle: const TextStyle(
        color: AppColors.lightTextPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      toolbarTextStyle: const TextStyle(
        color: AppColors.lightTextSecondary,
        fontSize: 17,
        fontWeight: FontWeight.w400,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.lightTextPrimary,
        size: 24,
      ),
    ),

    // Card with subtle shadow
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: AppColors.lightBorder,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Premium buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.lightBorder,
        disabledForegroundColor: AppColors.lightTextDisabled,
        elevation: 0,
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        minimumSize: const Size(120, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.lightTextPrimary,
        side: const BorderSide(
          color: AppColors.lightBorder,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        minimumSize: const Size(120, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
    ),

    // Input fields with clean design
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.lightBorder,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.lightBorder,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: const TextStyle(
        color: AppColors.lightTextTertiary,
        fontSize: 17,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: const TextStyle(
        color: AppColors.lightTextSecondary,
        fontSize: 17,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Typography with San Francisco style
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        height: 1.2,
        color: AppColors.lightTextPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.2,
        color: AppColors.lightTextPrimary,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
        height: 1.3,
        color: AppColors.lightTextPrimary,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.3,
        color: AppColors.lightTextPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        height: 1.3,
        color: AppColors.lightTextPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.4,
        color: AppColors.lightTextPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        height: 1.4,
        color: AppColors.lightTextPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.4,
        color: AppColors.lightTextPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.4,
        color: AppColors.lightTextSecondary,
      ),
      bodyLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.4,
        height: 1.5,
        color: AppColors.lightTextPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        height: 1.5,
        color: AppColors.lightTextSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        height: 1.4,
        color: AppColors.lightTextTertiary,
      ),
      labelLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: AppColors.lightTextPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
        color: AppColors.lightTextSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
        color: AppColors.lightTextTertiary,
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.lightDivider,
      thickness: 0.5,
      space: 1,
    ),

    iconTheme: const IconThemeData(
      color: AppColors.lightTextPrimary,
      size: 24,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightSurfaceVariant,
      deleteIconColor: AppColors.lightTextSecondary,
      disabledColor: AppColors.lightBorderLight,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      secondarySelectedColor: AppColors.accent.withValues(alpha: 0.15),
      labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      labelStyle: const TextStyle(
        color: AppColors.lightTextPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: const TextStyle(
        color: AppColors.lightTextSecondary,
      ),
      brightness: Brightness.light,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.lightTextTertiary,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.lightSurface,
      contentTextStyle: const TextStyle(
        color: AppColors.lightTextPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: AppColors.lightBorder,
          width: 1,
        ),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titleTextStyle: const TextStyle(
        color: AppColors.lightTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      contentTextStyle: const TextStyle(
        color: AppColors.lightTextSecondary,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      circularTrackColor: AppColors.lightBorderLight,
      linearTrackColor: AppColors.lightBorderLight,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return AppColors.lightBorderLight;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.lightBorder;
      }),
    ),
  );

  // ========================================
  // PREMIUM DARK THEME - OLED Black
  // ========================================
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // Color Scheme with high contrast for OLED
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Color(0xFF000000),
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: AppColors.primaryLight,

      secondary: AppColors.accent,
      onSecondary: Color(0xFF000000),
      secondaryContainer: Color(0xFF5A1A25),
      onSecondaryContainer: AppColors.accentLight,

      tertiary: AppColors.commodity,
      onTertiary: Color(0xFF000000),

      error: AppColors.errorDark,
      onError: Color(0xFF000000),
      errorContainer: Color(0xFF5F1918),
      onErrorContainer: AppColors.errorDark,

      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      onSurfaceVariant: AppColors.darkTextSecondary,

      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkBorderLight,

      shadow: Color(0x40000000),
      scrim: Color(0xB3000000),

      inverseSurface: AppColors.lightSurface,
      onInverseSurface: AppColors.lightTextPrimary,
      inversePrimary: AppColors.primaryDark,
    ),

    scaffoldBackgroundColor: AppColors.darkBackground,

    // AppBar with OLED black
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      shadowColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      toolbarTextStyle: TextStyle(
        color: AppColors.darkTextSecondary,
        fontSize: 17,
        fontWeight: FontWeight.w400,
      ),
      iconTheme: IconThemeData(
        color: AppColors.darkTextPrimary,
        size: 24,
      ),
    ),

    // Card with elevation on dark background
    cardTheme: CardThemeData(
      color: AppColors.darkSurfaceVariant,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: AppColors.darkBorder,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Premium buttons for dark mode
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.darkBorder,
        disabledForegroundColor: AppColors.darkTextDisabled,
        elevation: 0,
        shadowColor: AppColors.primary.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        minimumSize: const Size(120, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkTextPrimary,
        side: const BorderSide(
          color: AppColors.darkBorder,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        minimumSize: const Size(120, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
    ),

    // Input fields for dark mode
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.darkBorder,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.darkBorder,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.errorDark,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.errorDark,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: const TextStyle(
        color: AppColors.darkTextTertiary,
        fontSize: 17,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: const TextStyle(
        color: AppColors.darkTextSecondary,
        fontSize: 17,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Typography for dark mode
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        height: 1.2,
        color: AppColors.darkTextPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.2,
        color: AppColors.darkTextPrimary,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
        height: 1.3,
        color: AppColors.darkTextPrimary,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.3,
        color: AppColors.darkTextPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        height: 1.3,
        color: AppColors.darkTextPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.4,
        color: AppColors.darkTextPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        height: 1.4,
        color: AppColors.darkTextPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.4,
        color: AppColors.darkTextPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.4,
        color: AppColors.darkTextSecondary,
      ),
      bodyLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.4,
        height: 1.5,
        color: AppColors.darkTextPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        height: 1.5,
        color: AppColors.darkTextSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        height: 1.4,
        color: AppColors.darkTextTertiary,
      ),
      labelLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: AppColors.darkTextPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
        color: AppColors.darkTextSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
        color: AppColors.darkTextTertiary,
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.darkDivider,
      thickness: 0.5,
      space: 1,
    ),

    iconTheme: const IconThemeData(
      color: AppColors.darkTextPrimary,
      size: 24,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkSurfaceVariant,
      deleteIconColor: AppColors.darkTextSecondary,
      disabledColor: AppColors.darkBorderLight,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      secondarySelectedColor: AppColors.accent.withValues(alpha: 0.2),
      labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      labelStyle: const TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: const TextStyle(
        color: AppColors.darkTextSecondary,
      ),
      brightness: Brightness.dark,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkBackground,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.darkTextTertiary,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurfaceVariant,
      contentTextStyle: const TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: AppColors.darkBorder,
          width: 1,
        ),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titleTextStyle: const TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      contentTextStyle: const TextStyle(
        color: AppColors.darkTextSecondary,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      circularTrackColor: AppColors.darkBorder,
      linearTrackColor: AppColors.darkBorder,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return AppColors.darkBorder;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.darkBorderLight;
      }),
    ),
  );
}
