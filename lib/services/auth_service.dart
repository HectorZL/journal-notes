import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database_helper.dart';
import '../providers/auth_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
  
  // Logout user
  Future<void> logout() async {
    await _ref.read(authProvider.notifier).logout();
  }
  
  // Update user profile
  Future<void> updateProfile({String? name, String? email}) async {
    await _ref.read(authProvider.notifier).updateUserData(name: name, email: email);
  }
}
