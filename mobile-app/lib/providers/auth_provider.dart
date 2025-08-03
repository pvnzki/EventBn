import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final result = await ApiService.login(email, password);

      if (result['success']) {
        _user = User.fromJson(result['data']['user']);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _error = result['error'];
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Login failed: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final result = await ApiService.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      if (result['success']) {
        _user = User.fromJson(result['data']['user']);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _error = result['error'];
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Registration failed: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await ApiService.clearToken();
    _user = null;
    _error = null;
    notifyListeners();
  }

  // Check if user is already logged in
  Future<void> checkAuthStatus() async {
    try {
      final userData = await ApiService.getUserData();
      if (userData != null) {
        _user = User.fromJson(userData);
        notifyListeners();
      }
    } catch (e) {
      // If there's an error, user is not authenticated
      _user = null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
