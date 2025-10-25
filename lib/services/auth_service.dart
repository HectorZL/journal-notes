import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:notas_animo/services/face_recognition_service.dart';
import '../config/network_config.dart';
import '../data/database_helper.dart';
import '../providers/auth_provider.dart';

enum FaceRecognitionStatus {
  success,
  noFaceDetected,
  notRecognized,
  apiError,
  networkError,
  timeout,
  unknownError
}

const int _maxRetryAttempts = 3;
const Duration _retryDelay = Duration(seconds: 2);
const Duration _apiTimeout = Duration(seconds: 30);

class AuthService {
  final Ref _ref;
  final String baseUrl;
  String _apiBaseUrl;  
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  AuthService(this._ref, {this.baseUrl = 'http://localhost:8080'}) : _apiBaseUrl = baseUrl;

  void setApiBaseUrl(String url) {
    _apiBaseUrl = url;
    debugPrint('API base URL set to: $url');
  }
  
  bool isLoggedIn() {
    return _ref.read(authProvider).isAuthenticated;
  }
  
  String? getCurrentUserId() {
    return _ref.read(authProvider).userId;
  }
  
  String? getCurrentUserEmail() {
    return _ref.read(authProvider).userEmail;
  }
  
  String? getCurrentUserName() {
    return _ref.read(authProvider).userName;
  }
  
  Map<String, dynamic>? get currentUser {
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated) return null;
    
    return {
      'id': authState.userId,
      'email': authState.userEmail,
      'name': authState.userName,
      'profilePicturePath': authState.profilePicturePath,
    };
  }

  Future<Map<String, dynamic>> _makeApiRequest(
    String endpoint, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    String method = 'POST',
    int retryCount = 0,
  }) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl$endpoint');
      var request = http.MultipartRequest(method, uri);

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (files != null) {
        request.files.addAll(files);
      }

      debugPrint('Sending $method request to $uri (attempt ${retryCount + 1}/$_maxRetryAttempts)');
      final response = await request.send().timeout(_apiTimeout);
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(responseData.body);
      } else if (response.statusCode >= 500 && retryCount < _maxRetryAttempts) {
        debugPrint('Server error (${response.statusCode}), retrying...');
        await Future.delayed(_retryDelay * (retryCount + 1));
        return _makeApiRequest(
          endpoint,
          fields: fields,
          files: files,
          method: method,
          retryCount: retryCount + 1,
        );
      } else {
        final error = jsonDecode(responseData.body);
        throw Exception(error['detail'] ?? 'API request failed with status ${response.statusCode}');
      }
    } on TimeoutException {
      if (retryCount < _maxRetryAttempts) {
        debugPrint('Request timed out, retrying...');
        await Future.delayed(_retryDelay * (retryCount + 1));
        return _makeApiRequest(
          endpoint,
          fields: fields,
          files: files,
          method: method,
          retryCount: retryCount + 1,
        );
      }
      throw Exception('Request timed out after $_maxRetryAttempts attempts');
    } catch (e) {
      debugPrint('API request error: $e');
      rethrow;
    }
  }

  Future<bool> doesEmailExist(String email) async {
    if (_apiBaseUrl.isEmpty) {
      debugPrint('API base URL not set');
      return false;
    }
    
    try {
      final response = await NetworkConfig.makeRequest(
        '$_apiBaseUrl/check-email?email=${Uri.encodeComponent(email)}',
        method: 'GET',
      );
      
      if (response.statusCode == 200) {
        final data = response.body;
        return data.toLowerCase() == 'true';
      } else {
        debugPrint('Error checking email: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking if email exists: $e');
      return false;
    }
  }
  
  Future<FaceRecognitionStatus> _checkApiStatus() async {
    try {
      debugPrint('Checking API status...');
      final response = await http
          .get(Uri.parse('$_apiBaseUrl/status/'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'] == 'running'
            ? FaceRecognitionStatus.success
            : FaceRecognitionStatus.apiError;
        debugPrint('API status: $status');
        return status;
      }
      debugPrint('API status check failed: ${response.statusCode}');
      return FaceRecognitionStatus.apiError;
    } on TimeoutException {
      debugPrint('API status check timed out');
      return FaceRecognitionStatus.timeout;
    } catch (e) {
      debugPrint('API status check error: $e');
      return FaceRecognitionStatus.apiError;
    }
  }
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      debugPrint('Starting login for: $email');
      
      final isValid = await _dbHelper.validateUser(email, password);
      if (!isValid) {
        debugPrint('Invalid credentials for user: $email');
        return {'success': false, 'message': 'Correo o contraseña incorrectos'};
      }
      
      final user = await _dbHelper.getUserByEmail(email);
      if (user == null) {
        debugPrint('User not found in database: $email');
        return {'success': false, 'message': 'Usuario no encontrado'};
      }
      
      final userId = user[DatabaseHelper.columnId].toString();
      final userName = user[DatabaseHelper.columnName];
      final profilePicture = user[DatabaseHelper.columnProfilePicture];
      
      debugPrint('Login successful for user: $userName');
      await _ref.read(authProvider.notifier).login(
        userId, 
        email, 
        userName,
        profilePicture: profilePicture,
      );
      
      return {
        'success': true,
        'user': {
          'id': userId,
          'name': userName,
          'email': email,
          'profilePicturePath': profilePicture,
        }
      };
    } catch (e) {
      debugPrint('Login error: $e');
      return {
        'success': false, 
        'message': 'Error al iniciar sesión. Por favor, inténtalo de nuevo.'
      };
    }
  }
  
  Future<Map<String, dynamic>> loginWithFace(File faceImage) async {
    try {
      // Check if the image is valid
      if (!await faceImage.exists()) {
        debugPrint('Face image does not exist at path: ${faceImage.path}');
        return {
          'success': false,
          'message': 'La imagen no es válida o no se pudo cargar',
        };
      }

      debugPrint('Iniciando reconocimiento facial...');
      
      // Ensure the base URL is properly formatted
      String formattedUrl = _apiBaseUrl;
      if (!formattedUrl.endsWith('/')) {
        formattedUrl = '${formattedUrl}/';
      }
      
      debugPrint('Using formatted API URL: $formattedUrl');
      
      // Call face recognition service
      try {
        final faceService = FaceRecognitionService(baseUrl: formattedUrl);
        debugPrint('Llamando a la API de reconocimiento facial en: ${formattedUrl}recognize');
        
        final recognitionResult = await faceService.recognizeFace(faceImage);
        debugPrint('Resultado del reconocimiento: $recognitionResult');

        if (recognitionResult['status'] == 'success' && 
            recognitionResult['results'] != null && 
            recognitionResult['results'].isNotEmpty) {
          
          final recognizedName = recognitionResult['results'][0]['name']?.toString() ?? '';
          debugPrint('Nombre reconocido: $recognizedName');
          
          if (recognizedName.isNotEmpty) {
            // Get user by name from the database
            final user = await _dbHelper.getUserByName(recognizedName);
            
            if (user != null) {
              // Log the user in
              await _ref.read(authProvider.notifier).login(
                user[DatabaseHelper.columnId].toString(),
                user[DatabaseHelper.columnEmail],
                user[DatabaseHelper.columnName],
                profilePicture: user[DatabaseHelper.columnProfilePicture],
              );

              return {
                'success': true,
                'message': 'Inicio de sesión exitoso',
                'user': {
                  'id': user[DatabaseHelper.columnId],
                  'name': user[DatabaseHelper.columnName],
                  'email': user[DatabaseHelper.columnEmail],
                },
              };
            } else {
              debugPrint('No se encontró usuario con el nombre: $recognizedName');
              return {
                'success': false,
                'message': 'Usuario no encontrado',
              };
            }
          }
        }
        
        return {
          'success': false,
          'message': 'No se pudo reconocer ningún rostro registrado',
        };
      } catch (e) {
        debugPrint('Error en el reconocimiento facial: $e');
        return {
          'success': false,
          'message': 'Error al procesar el reconocimiento facial. Por favor, verifica la URL del servidor e inténtalo de nuevo.',
          'error': e.toString(),
        };
      }
    } catch (e) {
      debugPrint('Error en loginWithFace: $e');
      return {
        'success': false,
        'message': 'Error al procesar la imagen. Por favor, inténtalo de nuevo.',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> registerFace(
    String userId,
    String userName,
    File faceImage, {
    int retryCount = 0,
  }) async {
    try {
      debugPrint('Starting face registration for user: $userName');

      final apiStatus = await _checkApiStatus();
      if (apiStatus != FaceRecognitionStatus.success) {
        return _handleFaceRecognitionError(apiStatus);
      }

      final imageStream = http.ByteStream(faceImage.openRead());
      final length = await faceImage.length();
      final multipartFile = http.MultipartFile(
        'file',
        imageStream,
        length,
        filename: 'register_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      debugPrint('Sending face registration request...');
      final response = await _makeApiRequest(
        '/register_face_from_local_path/',
        fields: {'nombre': userName},
        files: [multipartFile],
      );

      debugPrint('Face registration successful for user: $userName');
      return {
        'success': true,
        'message': 'Rostro registrado exitosamente',
        'data': response,
      };
    } on TimeoutException {
      if (retryCount < _maxRetryAttempts) {
        debugPrint('Registration timeout, retrying...');
        await Future.delayed(_retryDelay * (retryCount + 1));
        return registerFace(
          userId,
          userName,
          faceImage,
          retryCount: retryCount + 1,
        );
      }
      return _handleFaceRecognitionError(FaceRecognitionStatus.timeout);
    } catch (e) {
      debugPrint('Error in registerFace: $e');
      return _handleFaceRecognitionError(FaceRecognitionStatus.unknownError);
    }
  }

  Map<String, dynamic> _handleFaceRecognitionError(
    FaceRecognitionStatus status, {
    String? customMessage,
  }) {
    String message = customMessage ?? '';
    
    if (message.isEmpty) {
      switch (status) {
        case FaceRecognitionStatus.noFaceDetected:
          message = 'No se detectó ningún rostro en la imagen';
          break;
        case FaceRecognitionStatus.notRecognized:
          message = 'Rostro no reconocido';
          break;
        case FaceRecognitionStatus.apiError:
          message = 'Error en el servidor de reconocimiento facial';
          break;
        case FaceRecognitionStatus.networkError:
          message = 'Error de conexión. Verifica tu conexión a internet';
          break;
        case FaceRecognitionStatus.timeout:
          message = 'Tiempo de espera agotado. Intenta de nuevo';
          break;
        case FaceRecognitionStatus.unknownError:
        default:
          message = 'Error desconocido. Por favor, intenta de nuevo';
      }
    }

    debugPrint('Face recognition error: $message');
    return {
      'success': false,
      'message': message,
      'status': status,
    };
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password, {
    File? profileImage,
    String? apiBaseUrl,
    File? faceImage,
  }) async {
    try {
      debugPrint('Starting registration for: $email');
      
      // Check if email already exists
      final existingUser = await _dbHelper.getUserByEmail(email);
      if (existingUser != null) {
        return {'success': false, 'message': 'Este correo ya está registrado'};
      }

      // Register face if image is provided
      if (faceImage != null) {

        setApiBaseUrl(apiBaseUrl ?? 'localhost:8080');
        final faceService = FaceRecognitionService(baseUrl: apiBaseUrl ?? 'localhost:8080');
        final faceResult = await faceService.registerFace(faceImage, name);
        
        if (!faceResult['success']) {
          return {
            'success': false,
            'message': faceResult['message'] ?? 'Error al registrar el rostro',
          };
        }
      }

      // Create user data map
      final userData = {
        DatabaseHelper.columnName: name,
        DatabaseHelper.columnEmail: email,
        DatabaseHelper.columnPassword: password,
        if (profileImage != null)
          DatabaseHelper.columnProfilePicture: profileImage.path,
      };

      // Insert user into database
      final userId = await _dbHelper.insertUser(userData);

      // Log the user in after successful registration
      await _ref.read(authProvider.notifier).login(
        userId.toString(),
        email,
        name,
        profilePicture: profileImage?.path,
      );

      debugPrint('Registration successful for user: $email');
      return {
        'success': true,
        'message': 'Registro exitoso',
        'user': {
          'id': userId,
          'name': name,
          'email': email,
          'profilePicturePath': profileImage?.path,
        }
      };
    } catch (e) {
      debugPrint('Error during registration: $e');
      return {
        'success': false,
        'message': 'Error durante el registro: ${e.toString()}',
      };
    }
  }

  Future<bool> updateProfile({
    required String userId,
    required String name,
    required String email,
    String? profilePicturePath,
  }) async {
    try {
      // Update in local database
      final rowsAffected = await _dbHelper.updateUser(
        int.tryParse(userId) ?? 0,
        name: name,
        email: email,
        profilePicture: profilePicturePath,
      );

      if (rowsAffected > 0) {
        // Update the auth state
        await _ref.read(authProvider.notifier).updateUserData(
              name: name,
              email: email,
              profilePicture: profilePicturePath,
            );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  Future<void> logout() async {
    debugPrint('Logging out user: ${getCurrentUserEmail()}');
    await _ref.read(authProvider.notifier).logout();
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref);
});
