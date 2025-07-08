import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final id = await _storage.read(key: 'user_id');
      final email = await _storage.read(key: 'user_email');
      final name = await _storage.read(key: 'user_name');
      
      if (id != null) {
        _isAuthenticated = true;
        _userId = id;
        _userEmail = email;
        _userName = name;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  Future<void> login(String id, String email, String name) async {
    try {
      await _storage.write(key: 'user_id', value: id);
      await _storage.write(key: 'user_email', value: email);
      await _storage.write(key: 'user_name', value: name);
      
      _isAuthenticated = true;
      _userId = id;
      _userEmail = email;
      _userName = name;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving user data: $e');
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
}
