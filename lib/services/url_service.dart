import 'package:shared_preferences/shared_preferences.dart';

class UrlService {
  static const String _ngrokUrlKey = 'ngrok_url';
  
  static Future<void> saveNgrokUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ngrokUrlKey, url);
  }

  static Future<String?> getNgrokUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ngrokUrlKey);
  }

  static Future<bool> hasSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_ngrokUrlKey);
  }
}
