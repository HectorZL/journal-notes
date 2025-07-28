import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  Locale _locale = const Locale('es', 'ES');

  Locale get locale => _locale;
  bool get isEnglish => _locale.languageCode == 'en';

  LanguageService() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);
    if (languageCode != null) {
      _locale = Locale(languageCode, languageCode == 'en' ? 'US' : 'ES');
      notifyListeners();
    }
  }

  Future<void> toggleLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (_locale.languageCode == 'en') {
      _locale = const Locale('es', 'ES');
      await prefs.setString(_languageKey, 'es');
    } else {
      _locale = const Locale('en', 'US');
      await prefs.setString(_languageKey, 'en');
    }
    notifyListeners();
  }
}

// Provider for Riverpod
final languageServiceProvider = ChangeNotifierProvider<LanguageService>((ref) {
  return LanguageService();
});
