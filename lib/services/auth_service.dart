import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database_helper.dart';
import '../providers/auth_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math'; // Import math library for sqrt function

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref);
});

class AuthService {
  final Ref _ref;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  AuthService(this._ref);
  
  // Check if user is logged in
  bool isLoggedIn() {
    return _ref.read(authProvider).isAuthenticated;
  }
  
  // Get current user ID
  String? getCurrentUserId() {
    return _ref.read(authProvider).userId;
  }
  
  // Get current user email
  String? getCurrentUserEmail() {
    return _ref.read(authProvider).userEmail;
  }
  
  // Get current user name
  String? getCurrentUserName() {
    return _ref.read(authProvider).userName;
  }
  
  // Get current user data as a map
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
  
  // Check if email exists in the system
  Future<bool> doesEmailExist(String email) async {
    try {
      // Query the database to check if email exists
      final db = await _dbHelper.database;
      final result = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email.toLowerCase()], // Case insensitive check
      );
      
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if email exists: $e');
      return false; // In case of error, default to false to prevent account enumeration
    }
  }
  
  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Input validation
      if (email.isEmpty || password.isEmpty) {
        return {'success': false, 'message': 'Por favor ingresa tu correo y contraseña'};
      }
      
      // First validate the credentials
      final isValid = await _dbHelper.validateUser(email, password);
      
      if (isValid) {
        // If credentials are valid, get the user data
        final user = await _dbHelper.getUserByEmail(email);
        
        if (user != null) {
          final userId = user[DatabaseHelper.columnId].toString();
          final userName = user[DatabaseHelper.columnName];
          final profilePicture = user[DatabaseHelper.columnProfilePicture];
          
          // Update auth state
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
        }
      }
      
      // If we get here, either credentials were invalid or user data couldn't be found
      return {'success': false, 'message': 'Correo o contraseña incorrectos'};
    } catch (e) {
      debugPrint('Login error: $e');
      return {'success': false, 'message': 'Error al iniciar sesión: $e'};
    }
  }
  
  // Register new user
  Future<Map<String, dynamic>> register(String name, String email, String password, {File? profileImage}) async {
    try {
      // Input validation
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        return {'success': false, 'message': 'Por favor completa todos los campos'};
      }
      
      // Ensure database is initialized
      try {
        await _dbHelper.database;
      } catch (e) {
        debugPrint('Database error: $e');
        return {'success': false, 'message': 'Error al conectar con la base de datos. Por favor, inténtalo de nuevo.'};
      }
      
      // Check if user already exists
      final existingUser = await _dbHelper.getUserByEmail(email);
      if (existingUser != null && existingUser.isNotEmpty) {
        return {'success': false, 'message': 'El correo ya está registrado'};
      }
      
      // Save profile image to app directory if provided
      String? profileImagePath;
      if (profileImage != null) {
        try {
          // Get application documents directory
          final directory = await getApplicationDocumentsDirectory();
          final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final String path = '${directory.path}/$fileName';
          
          // Copy the file to app's documents directory
          await profileImage.copy(path);
          profileImagePath = path;
          debugPrint('Profile image saved to: $path');
        } catch (e) {
          debugPrint('Error saving profile image: $e');
          // Don't fail registration if image save fails
        }
      }
      
      // Create new user
      final userId = await _dbHelper.insertUser({
        DatabaseHelper.columnName: name.trim(),
        DatabaseHelper.columnEmail: email.trim().toLowerCase(),
        DatabaseHelper.columnPassword: password,
        if (profileImagePath != null) DatabaseHelper.columnProfilePicture: profileImagePath,
      });
      
      if (userId > 0) {
        await _ref.read(authProvider.notifier).login(userId.toString(), email, name, profilePicture: profileImagePath);
        
        return {
          'success': true,
          'user': {
            'id': userId,
            'name': name,
            'email': email,
            'profilePicturePath': profileImagePath,
          }
        };
      } else {
        return {'success': false, 'message': 'Error al crear la cuenta'};
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      return {'success': false, 'message': 'Error al registrar el usuario: $e'};
    }
  }
  
  // Register new user with face authentication
  Future<Map<String, dynamic>> registerWithFace({
    required String name,
    required String email,
    required String password,
    required File faceImage,
  }) async {
    try {
      // 1. First, register the user normally
      final registerResult = await register(name, email, password, profileImage: faceImage);
      
      if (!registerResult['success']) {
        return registerResult;
      }
      
      // 2. Process face data and save it
      final userId = registerResult['user']['id'].toString();
      final faceDescriptor = await _processFaceData(faceImage);
      
      if (faceDescriptor == null) {
        return {
          'success': false,
          'message': 'No se pudo procesar el rostro. Por favor, intente con otra imagen.'
        };
      }
      
      // 3. Save face descriptor
      await _saveFaceDescriptor(userId, email, faceDescriptor);
      
      return registerResult;
    } catch (e) {
      debugPrint('Error in registerWithFace: $e');
      return {'success': false, 'message': 'Error al registrar con reconocimiento facial: $e'};
    }
  }
  
  // Process face data using ML Kit
  Future<Uint8List?> _processFaceData(File imageFile) async {
    try {
      // TODO: Implementar procesamiento de rostro con ML Kit
      // Por ahora, devolvemos los bytes de la imagen como placeholder
      return await imageFile.readAsBytes();
    } catch (e) {
      debugPrint('Error processing face data: $e');
      return null;
    }
  }
  
  // Save face descriptor to local storage
  Future<void> _saveFaceDescriptor(String userId, String email, Uint8List descriptor) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/face_${DateTime.now().millisecondsSinceEpoch}.dat');
      await file.writeAsBytes(descriptor);
      
      // Save reference in database using the dedicated method
      await _dbHelper.insertFaceAuthData(
        userId: userId,
        email: email,
        descriptorPath: file.path,
      );
    } catch (e) {
      debugPrint('Error saving face descriptor: $e');
      rethrow;
    }
  }
  
  // Logout user
  Future<void> logout() async {
    await _ref.read(authProvider.notifier).logout();
  }
  
  // Update user profile
  Future<void> updateProfile({String? name, String? email}) async {
    await _ref.read(authProvider.notifier).updateUserData(name: name, email: email);
  }
  
  // Calculate Euclidean distance between two face descriptors
  // Lower distance means more similar faces
  double _calculateFaceDistance(Uint8List descriptor1, Uint8List descriptor2) {
    if (descriptor1.length != descriptor2.length) {
      return double.infinity; // Different descriptor sizes are not comparable
    }
    
    double sum = 0.0;
    for (int i = 0; i < descriptor1.length; i++) {
      final diff = descriptor1[i] - descriptor2[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }

  // Authenticate with face
  Future<Map<String, dynamic>> loginWithFace(File faceImage) async {
    try {
      // 1. Process the input face
      final inputDescriptor = await _processFaceData(faceImage);
      if (inputDescriptor == null) {
        return {'success': false, 'message': 'No se pudo procesar el rostro.'};
      }
      
      // 2. Get all stored face descriptors
      final db = await _dbHelper.database;
      final storedFaces = await db.query('face_auth');
      
      double minDistance = double.infinity;
      Map<String, dynamic>? bestMatch;
      
      // 3. Compare with stored faces
      for (var storedFace in storedFaces) {
        try {
          final file = File(storedFace['descriptor_path'] as String);
          if (await file.exists()) {
            final storedDescriptor = await file.readAsBytes();
            
            // Compare face descriptors
            final distance = _calculateFaceDistance(inputDescriptor, storedDescriptor);
            debugPrint('Face comparison distance: $distance');
            
            // Update best match if this one is better
            if (distance < minDistance) {
              minDistance = distance;
              bestMatch = storedFace;
            }
          }
        } catch (e) {
          debugPrint('Error processing stored face: $e');
          continue; // Skip to next face if there's an error
        }
      }
      
      // 4. Check if we found a good enough match
      // Typical threshold values are between 0.6-1.0, adjust based on testing
      const threshold = 0.8; 
      if (bestMatch != null && minDistance <= threshold) {
        // Get user data
        final user = await _dbHelper.getUserByEmail(bestMatch['email'].toString());
        if (user != null) {
          // Update auth state
          await _ref.read(authProvider.notifier).login(
            user[DatabaseHelper.columnId].toString(),
            user[DatabaseHelper.columnEmail],
            user[DatabaseHelper.columnName],
            profilePicture: user[DatabaseHelper.columnProfilePicture],
          );
          
          return {
            'success': true,
            'user': {
              'id': user[DatabaseHelper.columnId],
              'name': user[DatabaseHelper.columnName],
              'email': user[DatabaseHelper.columnEmail],
              'profilePicturePath': user[DatabaseHelper.columnProfilePicture],
            },
            'confidence': 1.0 - (minDistance / threshold).clamp(0.0, 1.0), // Convert to confidence score (0-1)
          };
        }
      }
      
      return {
        'success': false, 
        'message': 'No se encontró una coincidencia para el rostro.',
        'confidence': bestMatch != null ? 1.0 - (minDistance / threshold).clamp(0.0, 1.0) : 0.0,
      };
    } catch (e, stackTrace) {
      debugPrint('Error in loginWithFace: $e\n$stackTrace');
      return {
        'success': false, 
        'message': 'Error en la autenticación facial: ${e.toString()}',
      };
    }
  }
}
