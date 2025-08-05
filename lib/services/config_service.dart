import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _serverUrlKey = 'server_url';
  static const String _defaultUrl = 'http://localhost:8000';
  
  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUrlKey) ?? _defaultUrl;
  }

  static Future<void> setServerUrl(String url) async {
    // Ensure the URL ends with a slash for proper concatenation
    if (!url.endsWith('/')) {
      url = '$url/';
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url);
  }

  static Future<String> getFaceRecognitionUrl() async {
    final baseUrl = await getServerUrl();
    return baseUrl.endsWith('/') ? '${baseUrl}recognize' : '$baseUrl/recognize';
  }

  static Future<String> getFaceRegistrationUrl() async {
    final baseUrl = await getServerUrl();
    return baseUrl.endsWith('/') ? '${baseUrl}register' : '$baseUrl/register';
  }

  static getBaseUrl() {}

  getApiBaseUrl() {}
}
