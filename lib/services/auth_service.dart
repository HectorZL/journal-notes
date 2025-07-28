import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database_helper.dart';
import '../providers/auth_provider.dart';

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
      
      // Ensure database is initialized
      try {
        await _dbHelper.database;
      } catch (e) {
        debugPrint('Database error: $e');
        return {'success': false, 'message': 'Error al conectar con la base de datos. Por favor, inténtalo de nuevo.'};
      }
      
      final user = await _dbHelper.getUserByEmail(email);
      
      if (user == null || user.isEmpty) {
        return {'success': false, 'message': 'Usuario no encontrado'};
      }
      
      final isValid = await _dbHelper.validateUser(email, password);
      
      if (isValid) {
        final userId = user[DatabaseHelper.columnId]?.toString();
        final userName = user[DatabaseHelper.columnName]?.toString() ?? 'Usuario';
        
        if (userId == null) {
          return {'success': false, 'message': 'Error en los datos del usuario'};
        }
        
        await _ref.read(authProvider).login(
          userId,
          email,
          userName,
        );
        
        return {
          'success': true,
          'user': {
            'id': userId,
            'name': userName,
            'email': email,
          }
        };
      } else {
        return {'success': false, 'message': 'Correo o contraseña incorrectos'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error al iniciar sesión: $e'};
    }
  }
  
  // Register new user
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
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
      
      // Create new user
      final userId = await _dbHelper.insertUser({
        DatabaseHelper.columnName: name.trim(),
        DatabaseHelper.columnEmail: email.trim().toLowerCase(),
        DatabaseHelper.columnPassword: password,
      });
      
      if (userId > 0) {
        await _ref.read(authProvider).login(userId.toString(), email, name);
        
        return {
          'success': true,
          'user': {
            'id': userId,
            'name': name,
            'email': email,
          }
        };
      } else {
        return {'success': false, 'message': 'Error al registrar el usuario'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error al registrar: $e'};
    }
  }
  
  // Logout user
  Future<void> logout() async {
    await _ref.read(authProvider).logout();
  }
  
  // Update user profile
  Future<void> updateProfile({String? name, String? email}) async {
    await _ref.read(authProvider).updateUserData(name: name, email: email);
  }
}
