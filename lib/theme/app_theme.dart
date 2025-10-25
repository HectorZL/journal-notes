import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

class AppTheme {
  static ThemeData getTheme({
    required ThemeModeOption themeMode,
    required Color primaryColor,
    required bool isBlackAndWhite,
    required Brightness platformBrightness,
  }) {
    final brightness = _getBrightness(themeMode, platformBrightness);
    final isDark = brightness == Brightness.dark;
    
    // For black and white mode, we'll use grayscale colors
    if (isBlackAndWhite) {
      return ThemeData(
        useMaterial3: true,
        brightness: brightness,
        colorScheme: ColorScheme(
          brightness: brightness,
          primary: isDark ? Colors.grey[900]! : Colors.grey[50]!,
          onPrimary: isDark ? Colors.white : Colors.black,
          primaryContainer: isDark ? Colors.grey[800]! : Colors.grey[100]!,
          onPrimaryContainer: isDark ? Colors.white : Colors.black,
          secondary: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          onSecondary: isDark ? Colors.white : Colors.black,
          error: Colors.red,
          onError: Colors.white,
          surface: isDark ? Colors.grey[900]! : Colors.grey[50]!,
          onSurface: isDark ? Colors.white : Colors.black,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(
            color: isDark ? Colors.white : Colors.black,
          ),
          titleTextStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: isDark ? Colors.grey[900] : Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
      );
    }

    // For color mode, create a color scheme from the primary color
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      primary: primaryColor,
      secondary: isDark 
          ? _lighten(primaryColor, 0.2) 
          : _darken(primaryColor, 0.2),
      tertiary: isDark 
          ? _lighten(primaryColor, 0.4) 
          : _darken(primaryColor, 0.4),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
  
  static Color _darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  static Color _lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }

  static Brightness _getBrightness(ThemeModeOption mode, Brightness platformBrightness) {
    switch (mode) {
      case ThemeModeOption.light:
        return Brightness.light;
      case ThemeModeOption.dark:
      case ThemeModeOption.black:
        return Brightness.dark;
      case ThemeModeOption.system:
      default:
        return platformBrightness;
    }
  }


}
