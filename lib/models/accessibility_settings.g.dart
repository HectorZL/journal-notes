// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accessibility_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccessibilitySettings _$AccessibilitySettingsFromJson(
        Map<String, dynamic> json) =>
    AccessibilitySettings(
      fontSize: $enumDecode(_$FontSizeOptionEnumMap, json['fontSize']),
      themeMode: $enumDecode(_$ThemeModeOptionEnumMap, json['themeMode']),
      colorBlindnessType: $enumDecode(
          _$ColorBlindnessTypeEnumMap, json['colorBlindnessType']),
      selectedColorIndex: json['selectedColorIndex'] as int,
      isBlackAndWhite: json['isBlackAndWhite'] as bool? ?? false,
    );

Map<String, dynamic> _$AccessibilitySettingsToJson(
        AccessibilitySettings instance) =>
    <String, dynamic>{
      'fontSize': _$FontSizeOptionEnumMap[instance.fontSize]!,
      'themeMode': _$ThemeModeOptionEnumMap[instance.themeMode]!,
      'colorBlindnessType':
          _$ColorBlindnessTypeEnumMap[instance.colorBlindnessType]!,
      'selectedColorIndex': instance.selectedColorIndex,
      'isBlackAndWhite': instance.isBlackAndWhite,
    };

const _$FontSizeOptionEnumMap = {
  FontSizeOption.small: 'small',
  FontSizeOption.medium: 'medium',
  FontSizeOption.large: 'large',
};

const _$ThemeModeOptionEnumMap = {
  ThemeModeOption.system: 'system',
  ThemeModeOption.light: 'light',
  ThemeModeOption.dark: 'dark',
  ThemeModeOption.black: 'black',
};

const _$ColorBlindnessTypeEnumMap = {
  ColorBlindnessType.none: 'none',
  ColorBlindnessType.protanopia: 'protanopia',
  ColorBlindnessType.deuteranopia: 'deuteranopia',
  ColorBlindnessType.tritanopia: 'tritanopia',
  ColorBlindnessType.achromatopsia: 'achromatopsia',
  ColorBlindnessType.daltonism: 'daltonism',
};
