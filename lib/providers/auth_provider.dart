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
  String? _profilePicturePath;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get profilePicturePath => _profilePicturePath;

  int? get userIdAsInt {
    if (_userId == null) return null;
    return int.tryParse(_userId!);
  }

  final Ref? _ref;
  
  AuthProvider([this._ref]) {
    loadUser();
  }

  Future<void> _setUser(String id, String? email, String? name, {String? profilePicture}) async {
    _isAuthenticated = true;
    _userId = id;
    _userEmail = email;
    _userName = name;
    _profilePicturePath = profilePicture;
    
    // Save to secure storage
    await _storage.write(key: 'user_id', value: id);
    if (email != null) await _storage.write(key: 'user_email', value: email);
    if (name != null) await _storage.write(key: 'user_name', value: name);
    if (profilePicture != null) {
      await _storage.write(key: 'profile_picture', value: profilePicture);
    }
    
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
      final id = await _storage.read(key: 'user_id');
      if (id != null) {
        final email = await _storage.read(key: 'user_email');
        final name = await _storage.read(key: 'user_name');
        final profilePicture = await _storage.read(key: 'profile_picture');
        await _setUser(id, email, name, profilePicture: profilePicture);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // Don't throw, just log the error
    }
  }

  Future<void> login(String id, String email, String name, {String? profilePicture}) async {
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
      if (profilePicture != null) {
        await _storage.write(key: 'profile_picture', value: profilePicture);
      }
      
      debugPrint('User data saved successfully');
      
      // Update the current user in memory
      await _setUser(id, email, name, profilePicture: profilePicture);
      
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
      _profilePicturePath = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
      rethrow;
    }
  }

  Future<void> updateUserData({String? name, String? email, String? profilePicture}) async {
    try {
      if (name != null) {
        await _storage.write(key: 'user_name', value: name);
        _userName = name;
      }
      if (email != null) {
        await _storage.write(key: 'user_email', value: email);
        _userEmail = email;
      }
      if (profilePicture != null) {
        await _storage.write(key: 'profile_picture', value: profilePicture);
        _profilePicturePath = profilePicture;
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
    _profilePicturePath = null;
    
    // Clear any user-specific data
    if (_ref != null) {
      await _ref!.read(notesProvider.notifier).setCurrentUser(null);
    }
    
    notifyListeners();
  }
}
