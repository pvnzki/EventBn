import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

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
    print('AuthProvider: Logging out user...');
    await ApiService.clearToken();
    _user = null;
    _error = null;
    print('AuthProvider: User logged out successfully');
    notifyListeners();
  }

  // Check if user is already logged in
  Future<void> checkAuthStatus() async {
    try {
      print('========== AuthProvider: Starting Auth Check ==========');
      print('AuthProvider: Checking auth status...');
      final userData = await ApiService.getUserData();

      if (userData != null) {
        print('AuthProvider: ✅ User data found, user is authenticated');
        print('AuthProvider: User data keys: ${userData.keys.toList()}');
        print('AuthProvider: User email: ${userData['email']}');
        _user = User.fromJson(userData);
        print('AuthProvider: User object created - email: ${_user!.email}');
        notifyListeners();
      } else {
        print('AuthProvider: ❌ No valid user data, user is not authenticated');
        _user = null;
        notifyListeners();
      }
      print('AuthProvider: Final isAuthenticated status: $isAuthenticated');
      print('========== AuthProvider: Auth Check Complete ==========');
    } catch (e) {
      print('========== AuthProvider: Auth Check ERROR ==========');
      print('AuthProvider: Error checking auth status: $e');
      print('AuthProvider: Stack trace: ${StackTrace.current}');
      // If there's an error, user is not authenticated
      _user = null;
      notifyListeners();
      print('========== AuthProvider: Auth Check ERROR END ==========');
    }
  }

  // Refresh user data (e.g., after profile picture upload)
  Future<void> refreshUserData() async {
    try {
      print('AuthProvider: Refreshing user data...');
      final userData = await ApiService.getUserData();

      if (userData != null) {
        print('AuthProvider: ✅ User data refreshed successfully');
        _user = User.fromJson(userData);
        notifyListeners();
      } else {
        print('AuthProvider: ❌ Failed to refresh user data');
      }
    } catch (e) {
      print('AuthProvider: Error refreshing user data: $e');
      // Don't log out on refresh error, just log it
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
