import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NetworkConfig {
  static const bool allowAnyUrl = true;
  static const Duration defaultTimeout = Duration(seconds: 30);
  
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true', // Skip ngrok browser warning
  };
  
  static Future<http.Response> makeRequest(
    String url, {
    String method = 'GET',
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final uri = Uri.parse(url);
      final requestHeaders = {...defaultHeaders, ...?headers};
      
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(
            uri,
            headers: requestHeaders,
            body: body,
          ).timeout(defaultTimeout);
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: requestHeaders,
            body: body,
          ).timeout(defaultTimeout);
          break;
        case 'DELETE':
          response = await http.delete(
            uri,
            headers: requestHeaders,
            body: body,
          ).timeout(defaultTimeout);
          break;
        case 'GET':
        default:
          response = await http.get(
            uri,
            headers: requestHeaders,
          ).timeout(defaultTimeout);
      }
      
      if (response.statusCode >= 400) {
        debugPrint('Network error - Status: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
      
      return response;
    } catch (e) {
      debugPrint('Network request error: $e');
      rethrow;
    }
  }
  
  static String normalizeUrl(String url) {
    if (!url.startsWith('http')) {
      return 'http://$url';
    }
    return url;
  }
}
