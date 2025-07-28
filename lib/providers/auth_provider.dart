import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers/providers.dart';

final authProvider = ChangeNotifierProvider<AuthProvider>((ref) => AuthProvider());

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  bool _isAuthenticated = false;
  String? _userId;
  String? _userEmail;
  String? _userName;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userName => _userName;

  int? get userIdAsInt {
    if (_userId == null) return null;
    return int.tryParse(_userId!);
  }

  final Ref? _ref;
  
  AuthProvider([this._ref]) {
    loadUser();
  }

  get id => null;

  Future<void> _setUser(String id, String? email, String? name) async {
    _isAuthenticated = true;
    _userId = id;
    _userEmail = email;
    _userName = name;
    
    // Update notes provider with the new user ID
    if (_ref != null) {
      final userId = int.tryParse(id);
      if (userId != null && userId > 0) {
        await _ref!.read(notesProvider.notifier).setCurrentUser(userId);
      } else {
        debugPrint('Invalid user ID format: $id');
        await _ref!.read(notesProvider.notifier).setCurrentUser(null);
      }
    }
    
    notifyListeners();
  }

  Future<void> loadUser() async {
    try {
      debugPrint('Loading user from secure storage...');
      
      // Read all user data in parallel
      final results = await Future.wait([
        _storage.read(key: 'user_id'),
        _storage.read(key: 'user_email'),
        _storage.read(key: 'user_name'),
      ]);
      
      final id = results[0];
      final email = results[1];
      final name = results[2];
      
      debugPrint('Retrieved user data - ID: $id, Email: $email');
      
      if (id != null && id.isNotEmpty) {
        await _setUser(id, email, name);
        debugPrint('User loaded successfully from secure storage');
      } else {
        debugPrint('No user ID found in secure storage');
        await _clearUser();
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading user: $e\n$stackTrace');
      await _clearUser();
      rethrow;
    }
  }

  Future<void> login(String id, String email, String name) async {
    try {
      // Validate user ID before proceeding
      final userId = int.tryParse(id);
      if (userId == null || userId <= 0) {
        throw Exception('Formato de ID de usuario inválido');
      }
      
      debugPrint('Saving user data to secure storage - ID: $id, Email: $email');
      
      // Save all user data to secure storage
      await _storage.write(key: 'user_id', value: id);
      await _storage.write(key: 'user_email', value: email);
      await _storage.write(key: 'user_name', value: name);
      
      debugPrint('User data saved successfully');
      
      // Update the current user in memory
      await _setUser(id, email, name);
      
      debugPrint('User logged in successfully - ID: $id, Email: $email');
    } catch (e, stackTrace) {
      debugPrint('Error during login: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _storage.deleteAll();
      _isAuthenticated = false;
      _userId = null;
      _userEmail = null;
      _userName = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
      rethrow;
    }
  }

  Future<void> updateUserData({String? name, String? email}) async {
    try {
      if (name != null) {
        await _storage.write(key: 'user_name', value: name);
        _userName = name;
      }
      if (email != null) {
        await _storage.write(key: 'user_email', value: email);
        _userEmail = email;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user data: $e');
      rethrow;
    }
  }
  
  Future<void> _clearUser() async {
    _isAuthenticated = false;
    _userId = null;
    _userEmail = null;
    _userName = null;
    
    // Clear any user-specific data
    if (_ref != null) {
      await _ref!.read(notesProvider.notifier).setCurrentUser(null);
    }
    
    notifyListeners();
  }
}
