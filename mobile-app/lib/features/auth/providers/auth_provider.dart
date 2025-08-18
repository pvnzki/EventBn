import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      final prefs = await SharedPreferences.getInstance();
      final isAuthenticated = prefs.getBool('is_authenticated') ?? false;
      final userEmail = prefs.getString('user_email');

      if (isAuthenticated && userEmail != null) {
        final now = DateTime.now();
        _user = User(
          id: 'user_${userEmail.hashCode}',
          firstName: userEmail.split('@')[0],
          lastName: 'User',
          email: userEmail,
          phoneNumber: null,
          createdAt: now,
          updatedAt: now,
        );
        _isAuthenticated = true;
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

    // Ensure result is valid and contains both user + token
    if (result != null && result['user'] != null && result['token'] != null) {
      _user = result['user'];
      _isAuthenticated = true;

      final token = result['token'];
      print('JWT Token: $token'); // For debugging

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', _user!.email);
      await prefs.setString('auth_token', token); // 🔥 store token
      await prefs.setBool('is_authenticated', true);

      _setLoading(false);
      return true;
    } else {
      _setError('Invalid email or password');
      _setLoading(false);
      return false;
    }
  } catch (e) {
    _setError(e.toString().replaceAll('Exception: ', ''));
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

      if (result['success'] == true && result['user'] != null) {
        _user = result['user'];
        _isAuthenticated = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', _user!.email);
        await prefs.setBool('is_authenticated', true);

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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.setBool('is_authenticated', false);

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

      if (result['success'] == true && result['user'] != null) {
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

      if (result['success'] == true) {
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

  void clearError() {
    _setError(null);
  }
}
