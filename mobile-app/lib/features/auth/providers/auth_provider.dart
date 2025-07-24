import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Initialize authentication state
  Future<void> initializeAuth() async {
    _setLoading(true);
    try {
      final token = await _authService.getStoredToken();
      if (token != null) {
        final userData = await _authService.getCurrentUser();
        if (userData != null) {
          _user = userData;
          _isAuthenticated = true;
        }
      }
    } catch (e) {
      _setError('Failed to initialize authentication');
    } finally {
      _setLoading(false);
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.login(email, password);
      if (result['success']) {
        _user = result['user'];
        _isAuthenticated = true;
        _setLoading(false);
        return true;
      } else {
        _setError(result['message'] ?? 'Login failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );

      if (result['success']) {
        _user = result['user'];
        _isAuthenticated = true;
        _setLoading(false);
        return true;
      } else {
        _setError(result['message'] ?? 'Registration failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _authService.logout();
      _user = null;
      _isAuthenticated = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to logout');
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    if (_user == null) return false;

    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );

      if (result['success']) {
        _user = result['user'];
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result['message'] ?? 'Update failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (result['success']) {
        _setLoading(false);
        return true;
      } else {
        _setError(result['message'] ?? 'Password change failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // Clear error
  void clearError() {
    _setError(null);
  }
}
