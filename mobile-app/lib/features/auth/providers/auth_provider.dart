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
    print('🔄 AuthProvider: Initializing authentication...');
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAuthenticated = prefs.getBool('is_authenticated') ?? false;
      final userEmail = prefs.getString('user_email');
      final authToken = prefs.getString('auth_token');

      print(
          '🔍 AuthProvider: isAuthenticated=$isAuthenticated, email=$userEmail, hasToken=${authToken != null}');

      if (isAuthenticated && userEmail != null && authToken != null) {
        // Get the actual user data from the backend/token instead of creating from email hash
        print('🔍 AuthProvider: Getting user data from AuthService...');
        final user = await _authService.getCurrentUser();

        if (user != null) {
          _user = user;
          _isAuthenticated = true;
          print(
              '✅ AuthProvider: User initialized from backend - ID: ${_user!.id}, Email: ${_user!.email}');
        } else {
          // Fallback: create user from stored data (this should be rare)
          print('⚠️ AuthProvider: Fallback to creating user from stored email');
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
          print(
              '⚠️ AuthProvider: User initialized from fallback - ID: ${_user!.id}, Email: ${_user!.email}');
        }
      } else {
        print('❌ AuthProvider: Authentication data incomplete, user not set');
        _user = null;
        _isAuthenticated = false;
      }
    } catch (e) {
      print('❌ AuthProvider: Error initializing authentication: $e');
      _setError('Failed to initialize authentication');
    } finally {
      _setLoading(false);
      print(
          '🏁 AuthProvider: Initialization complete. User: ${_user?.id}, Authenticated: $_isAuthenticated');
    }
  }

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.login(email, password);
      print('🔄 [AUTH_PROVIDER] Login result: $result');

      // Check if 2FA is required
      if (result['requiresTwoFactor'] == true) {
        print('🔐 [AUTH_PROVIDER] Two-factor authentication required');
        _setLoading(false);
        return {
          'success': false,
          'requiresTwoFactor': true,
          'twoFactorMethod': result['twoFactorMethod'] ?? 'app',
          'email': email,
          'password': password,
        };
      }

      // Ensure result is valid and contains both user + token
      if (result['user'] != null && result['token'] != null) {
        // Parse the user data into a User object
        final userData = result['user'];
        if (userData is Map<String, dynamic>) {
          _user = User.fromJson(userData);
        } else {
          _user = userData as User;
        }
        _isAuthenticated = true;

        final token = result['token'];
        print('JWT Token: $token'); // For debugging

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', _user!.email);
        await prefs.setString('auth_token', token); // 🔥 store token
        await prefs.setBool('is_authenticated', true);

        _setLoading(false);
        return {'success': true};
      } else {
        _setError('Invalid email or password');
        _setLoading(false);
        return {'success': false, 'message': 'Invalid email or password'};
      }
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return {'success': false, 'message': e.toString().replaceAll('Exception: ', '')};
    }
  }

  // Complete 2FA login process
  Future<void> completeTwoFactorLogin(Map<String, dynamic> result) async {
    if (result['user'] != null && result['token'] != null) {
      // Parse the user data into a User object
      final userData = result['user'];
      if (userData is Map<String, dynamic>) {
        _user = User.fromJson(userData);
      } else {
        _user = userData as User;
      }
      _isAuthenticated = true;

      final token = result['token'];
      print('JWT Token (2FA): $token'); // For debugging

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', _user!.email);
      await prefs.setString('auth_token', token);
      await prefs.setBool('is_authenticated', true);

      notifyListeners();
      print('✅ [AUTH_PROVIDER] 2FA login completed for: ${_user!.email}');
    }
  }

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      print('🔄 [AUTH_PROVIDER] Registering user: $email');
      
      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );

      if (result['success'] == true && result['user'] != null) {
        // Parse the user data into a User object
        final userData = result['user'];
        if (userData is Map<String, dynamic>) {
          _user = User.fromJson(userData);
        } else {
          _user = userData as User;
        }
        _isAuthenticated = true;

        final token = result['token'];
        print('🔄 [AUTH_PROVIDER] Registration successful, storing token');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', _user!.email);
        await prefs.setString('auth_token', token);
        await prefs.setBool('is_authenticated', true);

        print('✅ [AUTH_PROVIDER] Registration completed for: ${_user!.email}');
        _setLoading(false);
        return true;
      } else {
        print('❌ [AUTH_PROVIDER] Registration failed: ${result['message']}');
        _setError(result['message'] ?? 'Registration failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('❌ [AUTH_PROVIDER] Registration error: $e');
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
        // Parse the user data into a User object
        final userData = result['user'];
        if (userData is Map<String, dynamic>) {
          _user = User.fromJson(userData);
        } else {
          _user = userData as User;
        }
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

  // Update user data (for profile updates)
  void updateUser(User updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }
}
