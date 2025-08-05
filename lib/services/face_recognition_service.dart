import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';

class FaceRecognitionService {
  final String baseUrl;
  
  FaceRecognitionService({required this.baseUrl});

  /// Verifica si un rostro ya está registrado en el sistema
  Future<Map<String, dynamic>> verifyFace(File imageFile) async {
    try {
      final result = await recognizeFace(imageFile);
      return {
        'success': result['status'] == 'success' && result['results']?.isNotEmpty == true,
        'isRegistered': result['status'] == 'success' && result['results']?.isNotEmpty == true,
        'message': result['status'] == 'success' ? 'Rostro reconocido' : 'Rostro no reconocido',
        'data': result,
      };
    } catch (e) {
      return {
        'success': false,
        'isRegistered': false,
        'message': 'Error al verificar el rostro: $e',
        'data': null,
      };
    }
  }

  /// Registra un nuevo rostro en el sistema
  Future<Map<String, dynamic>> registerFace(File imageFile, String name) async {
    try {
      // Primero verificar si el rostro ya está registrado
      final recognitionResult = await recognizeFace(imageFile);
      
      if (recognitionResult['status'] == 'success' && 
          recognitionResult['results']?.isNotEmpty == true) {
        return {
          'success': false,
          'message': 'Este rostro ya está registrado en el sistema',
          'data': recognitionResult,
        };
      }

      // Si no está registrado, proceder con el registro
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/register'),
      );

      // Add the image file
      final mimeType = lookupMimeType(imageFile.path);
      final fileExtension = mimeType?.split('/')[1] ?? 'jpg';
      
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType('image', fileExtension),
      ));
      
      // Add name as form field
      request.fields['name'] = name;
      request.fields['save_to_db'] = 'true'; // Indicar al backend que guarde en MySQL

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);
      
      if (response.statusCode == 200) {
        if (jsonResponse['success'] == true) {
          return {
            'success': true,
            'message': 'Rostro registrado correctamente en la base de datos',
            'data': jsonResponse,
          };
        } else {
          return {
            'success': false,
            'message': 'Error al guardar en la base de datos: ${jsonResponse['message'] ?? 'Error desconocido'}',
            'data': jsonResponse,
          };
        }
      } else {
        throw Exception('Failed to register face: ${response.statusCode} - $responseData');
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error al registrar el rostro: $e',
        'data': null,
      };
    }
  }

  /// Recognize a face from an image file
  Future<Map<String, dynamic>> recognizeFace(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(baseUrl + 'recognize'),
      );

      // Add the image file
      final mimeType = lookupMimeType(imageFile.path);
      final fileExtension = mimeType?.split('/')[1] ?? 'jpg';
      
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType('image', fileExtension),
      ));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        return json.decode(responseData);
      } else {
        throw Exception('Failed to recognize face: ${response.statusCode} - $responseData');
      }
    } catch (e) {
      throw Exception('Error recognizing face: $e');
    }
  }

  /// Delete a registered face
  Future<Map<String, dynamic>> deleteFace(int personaId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/faces/$personaId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete face: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting face: $e');
    }
  }

  /// List all known faces
  Future<List<Map<String, dynamic>>> listKnownFaces() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/faces'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(
            data['faces']?.map((face) => {
              'id': face['id'],
              'name': face['name'],
            }) ?? []
          );
        }
        throw Exception('Failed to list known faces: ${data['message']}');
      } else {
        throw Exception('Failed to list known faces: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error listing known faces: $e');
    }
  }

  /// Get API status
  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting status: $e');
    }
  }

  /// Verifica si una URL es válida
  static bool isValidNgrokUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }

  // Helper method to get temporary directory
  static Future<Directory> getTemporaryDirectory() async {
    return await getTemporaryDirectory();
  }
}
