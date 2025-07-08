import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database_helper.dart';
import '../providers/auth_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref,
    DatabaseHelper(),
  );
});

class AuthService {
  final Ref _ref;
  final DatabaseHelper _dbHelper;
  
  AuthService(this._ref, this._dbHelper);
  
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
  
  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final user = await _dbHelper.getUserByEmail(email);
      
      if (user == null) {
        return {'success': false, 'message': 'Usuario no encontrado'};
      }
      
      final isValid = await _dbHelper.validateUser(email, password);
      
      if (isValid) {
        await _ref.read(authProvider).login(
          user[DatabaseHelper.columnId].toString(),
          email,
          user[DatabaseHelper.columnName],
        );
        
        return {
          'success': true,
          'user': {
            'id': user[DatabaseHelper.columnId],
            'name': user[DatabaseHelper.columnName],
            'email': email,
          }
        };
      } else {
        return {'success': false, 'message': 'Contraseña incorrecta'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error al iniciar sesión: $e'};
    }
  }
  
  // Register new user
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      // Check if user already exists
      final existingUser = await _dbHelper.getUserByEmail(email);
      if (existingUser != null) {
        return {'success': false, 'message': 'El correo ya está registrado'};
      }
      
      // Create new user
      final userId = await _dbHelper.insertUser({
        DatabaseHelper.columnName: name,
        DatabaseHelper.columnEmail: email,
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
