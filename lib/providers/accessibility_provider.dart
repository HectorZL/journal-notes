import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/accessibility_settings.dart';
import 'theme_provider.dart';

class AccessibilityNotifier extends StateNotifier<AccessibilitySettings> {
  AccessibilityNotifier() : super(const AccessibilitySettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AccessibilitySettings.load();
    state = settings;
  }

  Future<void> updateSettings(AccessibilitySettings newSettings) async {
    state = newSettings;
    await state.save();
  }

  Future<void> setFontSize(FontSizeOption fontSize) async {
    state = state.copyWith(fontSize: fontSize);
    await state.save();
  }

  Future<void> setThemeMode(ThemeModeOption themeMode) async {
    state = state.copyWith(themeMode: themeMode);
    await state.save();
  }

  Future<void> setColorBlindnessType(ColorBlindnessType type) async {
    state = state.copyWith(colorBlindnessType: type);
    await state.save();
  }

  Future<void> setSelectedColorIndex(int index) async {
    state = state.copyWith(selectedColorIndex: index);
    await state.save();
  }

  Future<void> setBlackAndWhite(bool isBlackAndWhite) async {
    state = state.copyWith(isBlackAndWhite: isBlackAndWhite);
    await state.save();
  }
}

final accessibilityProvider = StateNotifierProvider<AccessibilityNotifier, AccessibilitySettings>(
  (ref) => AccessibilityNotifier(),
);
