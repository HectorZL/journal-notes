import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
  
  // Language code
  bool get isEnglish => locale.languageCode == 'en';
  
  // Common
  String get appName => isEnglish ? 'Mood Notes' : 'Notas de Estado de Ánimo';
  
  // Profile Screen
  String get profileTitle => isEnglish ? 'Profile' : 'Perfil';
  String get accountSection => isEnglish ? 'Account' : 'Cuenta';
  String get helpSection => isEnglish ? 'Help' : 'Ayuda';
  String get accessibilitySection => isEnglish ? 'Accessibility' : 'Accesibilidad';
  String get appSection => isEnglish ? 'Application' : 'Aplicación';
  String get logoutButton => isEnglish ? 'Logout' : 'Cerrar sesión';
  String get versionLabel => isEnglish ? 'Version' : 'Versión';
  
  // Profile Options
  String get editProfile => isEnglish ? 'Edit Profile' : 'Editar perfil';
  String get changePassword => isEnglish ? 'Change Password' : 'Cambiar contraseña';
  String get language => isEnglish ? 'Language' : 'Idioma';
  String get english => 'English';
  String get spanish => 'Español';
  String get faqs => isEnglish ? 'FAQs' : 'Preguntas frecuentes';
  
  // Accessibility
  String get accessibilitySettings => isEnglish 
      ? 'Accessibility Settings' 
      : 'Configuración de accesibilidad';
  String get accessibilityDescription => isEnglish
      ? 'Customize the app appearance according to your preferences and accessibility needs.'
      : 'Personaliza la apariencia de la aplicación según tus preferencias y necesidades de accesibilidad.';
  
  // Logout Dialog
  String get logoutDialogTitle => isEnglish ? 'Logout' : 'Cerrar sesión';
  String get logoutDialogContent => isEnglish
      ? 'Are you sure you want to logout?'
      : '¿Estás seguro de que quieres cerrar sesión?';
  String get cancel => isEnglish ? 'Cancel' : 'Cancelar';
  
  // Success Messages
  String get profileUpdated => isEnglish 
      ? 'Profile updated successfully' 
      : 'Perfil actualizado correctamente';
  String get passwordUpdated => isEnglish
      ? 'Password updated successfully'
      : 'Contraseña actualizada correctamente';
  
  // FAQ Screen
  String get faqTitle => isEnglish ? 'FAQs' : 'Preguntas frecuentes';
  
  // Add more strings as needed
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
