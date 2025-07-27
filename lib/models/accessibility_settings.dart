import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme.dart';

part 'accessibility_settings.g.dart';

enum FontSizeOption { small, medium, large }
enum ColorBlindnessType { none, protanopia, deuteranopia, tritanopia, achromatopsia }

@JsonSerializable()
class AccessibilitySettings {
  final FontSizeOption fontSize;
  final ThemeModeOption themeMode;
  final ColorBlindnessType colorBlindnessType;
  final int selectedColorIndex;
  final bool isBlackAndWhite;

  static const String _key = 'accessibility_settings';
  static const List<Color> colorPalette = [
    Color(0xFF6200EE), // Purple
    Color(0xFF03DAC6), // Teal
    Color(0xFFE91E63), // Pink
    Color(0xFF4CAF50), // Green
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF3F51B5), // Indigo
  ];

  const AccessibilitySettings({
    this.fontSize = FontSizeOption.medium,
    this.themeMode = ThemeModeOption.system,
    this.colorBlindnessType = ColorBlindnessType.none,
    this.selectedColorIndex = 0,
    this.isBlackAndWhite = false,
  });

  factory AccessibilitySettings.fromJson(Map<String, dynamic> json) => 
      _$AccessibilitySettingsFromJson(json);

  Map<String, dynamic> toJson() => _$AccessibilitySettingsToJson(this);

  double get fontSizeScale {
    switch (fontSize) {
      case FontSizeOption.small:
        return 0.9;
      case FontSizeOption.medium:
        return 1.0;
      case FontSizeOption.large:
        return 1.2;
    }
  }

  Color get selectedColor => colorPalette[selectedColorIndex];

  AccessibilitySettings copyWith({
    FontSizeOption? fontSize,
    ThemeModeOption? themeMode,
    ColorBlindnessType? colorBlindnessType,
    int? selectedColorIndex,
    bool? isBlackAndWhite,
  }) {
    return AccessibilitySettings(
      fontSize: fontSize ?? this.fontSize,
      themeMode: themeMode ?? this.themeMode,
      colorBlindnessType: colorBlindnessType ?? this.colorBlindnessType,
      selectedColorIndex: selectedColorIndex ?? this.selectedColorIndex,
      isBlackAndWhite: isBlackAndWhite ?? this.isBlackAndWhite,
    );
  }

  static Future<AccessibilitySettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString != null) {
      try {
        return AccessibilitySettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(jsonString)),
        );
      } catch (e) {
        // If there's an error, return default settings
      }
    }
    return const AccessibilitySettings();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(toJson()));
  }
}
