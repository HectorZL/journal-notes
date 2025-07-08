import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Export the enum for use in other files
export 'theme_provider.dart' show ThemeModeOption, ThemeNotifier, ThemeState;

enum ThemeModeOption { system, light, dark, black }

class AppColor {
  final int value;
  final String name;

  const AppColor(this.value, this.name);

  Color get color => Color(value);

  Map<String, dynamic> toJson() => {'value': value, 'name': name};

  factory AppColor.fromJson(Map<String, dynamic> json) {
    return AppColor(json['value'] as int, json['name'] as String);
  }

  static const List<AppColor> defaultColors = [
    AppColor(0xFF6200EE, 'Purple'),
    AppColor(0xFF03DAC6, 'Teal'),
    AppColor(0xFFE91E63, 'Pink'),
    AppColor(0xFF4CAF50, 'Green'),
    AppColor(0xFFFF5722, 'Deep Orange'),
    AppColor(0xFF3F51B5, 'Indigo'),
  ];
}

ThemeModeOption themeModeOptionFromString(String value) {
  return ThemeModeOption.values.firstWhere(
    (e) => e.toString() == value,
    orElse: () => ThemeModeOption.system,
  );
}

class ThemeState {
  final ThemeModeOption themeMode;
  final double fontSizeScale;
  final AppColor primaryColor;
  final bool isBlackAndWhite;

  ThemeState({
    this.themeMode = ThemeModeOption.system,
    this.fontSizeScale = 1.0,
    AppColor? primaryColor,
    this.isBlackAndWhite = false,
  }) : primaryColor = primaryColor ?? AppColor.defaultColors.first;

  ThemeState copyWith({
    ThemeModeOption? themeMode,
    double? fontSizeScale,
    AppColor? primaryColor,
    bool? isBlackAndWhite,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      fontSizeScale: fontSizeScale ?? this.fontSizeScale,
      primaryColor: primaryColor ?? this.primaryColor,
      isBlackAndWhite: isBlackAndWhite ?? this.isBlackAndWhite,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  static const String _themeKey = 'theme_mode';
  static const String _fontSizeKey = 'font_size_scale';
  static const String _primaryColorKey = 'primary_color';
  static const String _isBlackAndWhiteKey = 'is_black_and_white';
  
  late final SharedPreferences _prefs;

  ThemeNotifier(SharedPreferences prefs) : _prefs = prefs, super(ThemeState()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    final themeString = _prefs.getString(_themeKey);
    final fontSizeScale = _prefs.getDouble(_fontSizeKey) ?? 1.0;
    final colorJson = _prefs.getString(_primaryColorKey);
    final isBlackAndWhite = _prefs.getBool(_isBlackAndWhiteKey) ?? false;
    
    AppColor? primaryColor;
    if (colorJson != null) {
      try {
        primaryColor = AppColor.fromJson(json.decode(colorJson));
      } catch (e) {
        // Handle error or use default
      }
    }
    
    state = state.copyWith(
      themeMode: themeString != null ? themeModeOptionFromString(themeString) : ThemeModeOption.system,
      fontSizeScale: fontSizeScale,
      primaryColor: primaryColor,
      isBlackAndWhite: isBlackAndWhite,
    );
  }

  Future<void> _saveThemeMode(ThemeModeOption mode) async {
    await _prefs.setString(_themeKey, mode.toString());
  }

  Future<void> _saveFontSizeScale(double scale) async {
    await _prefs.setDouble(_fontSizeKey, scale);
  }
  
  Future<void> _savePrimaryColor(AppColor color) async {
    await _prefs.setString(_primaryColorKey, json.encode(color.toJson()));
  }
  
  Future<void> _saveIsBlackAndWhite(bool isBlackAndWhite) async {
    await _prefs.setBool(_isBlackAndWhiteKey, isBlackAndWhite);
  }

  void setThemeMode(ThemeModeOption mode) {
    state = state.copyWith(themeMode: mode);
    _saveThemeMode(mode);
  }

  void setFontSizeScale(double scale) {
    state = state.copyWith(fontSizeScale: scale);
    _saveFontSizeScale(scale);
  }
  
  void setPrimaryColor(AppColor color) {
    state = state.copyWith(primaryColor: color);
    _savePrimaryColor(color);
  }
  
  void setBlackAndWhiteMode(bool isBlackAndWhite) {
    state = state.copyWith(isBlackAndWhite: isBlackAndWhite);
    _saveIsBlackAndWhite(isBlackAndWhite);
  }

  ThemeMode get currentThemeMode {
    switch (state.themeMode) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
      case ThemeModeOption.black: // Both dark and black use dark mode, we'll handle the difference in the UI
        return ThemeMode.dark;
      case ThemeModeOption.system:
      default:
        return ThemeMode.system;
    }
  }

  bool get isBlackTheme => state.themeMode == ThemeModeOption.black;
  
  bool get isBlackAndWhiteMode => state.isBlackAndWhite;
  
  Color get primaryColor => state.primaryColor.color;
  
  AppColor get currentPrimaryColor => state.primaryColor;

  double get textScaleFactor {
    return state.fontSizeScale;
  }
}

// Create a provider that can be overridden in main.dart
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  throw UnimplementedError('ThemeNotifier must be overridden in main.dart');
});
