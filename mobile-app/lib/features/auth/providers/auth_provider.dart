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
    print('🔄 [AUTH_PROVIDER] Initializing authentication...');
    _setLoading(true);
    try {
      // Check if we have a valid token and user data from AuthService
      final user = await _authService.getCurrentUser();
      final token = await _authService.getStoredToken();

      print('🔍 [AUTH_PROVIDER] Token exists: ${token != null}');
      print('🔍 [AUTH_PROVIDER] User data exists: ${user != null}');

      if (user != null && token != null) {
        // We have both token and user data - user is authenticated
        _user = user;
        _isAuthenticated = true;
        
        print('✅ [AUTH_PROVIDER] User authenticated from stored data');
        print('   - User ID: ${user.id}');
        print('   - Email: ${user.email}');
        print('   - Phone: ${user.phoneNumber}');
        print('   - Billing Address: ${user.billingAddress}');
        print('   - Date of Birth: ${user.dateOfBirth}');

        // Update SharedPreferences to be consistent
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', user.email);
        await prefs.setBool('is_authenticated', true);
        
      } else {
        // No valid authentication data found
        print('❌ [AUTH_PROVIDER] No valid authentication data found');
        
        // Ensure clean state by removing any partial data
        await _cleanPartialAuthData();
        
        _user = null;
        _isAuthenticated = false;
      }
    } catch (e) {
      print('❌ [AUTH_PROVIDER] Error initializing authentication: $e');
      
      // On error, ensure clean state
      await _cleanPartialAuthData();
      _user = null;
      _isAuthenticated = false;
      _setError('Failed to initialize authentication');
    } finally {
      _setLoading(false);
      print('🏁 [AUTH_PROVIDER] Initialization complete. User: ${_user?.id}, Authenticated: $_isAuthenticated');
    }
  }

  // Helper method to clean partial authentication data
  Future<void> _cleanPartialAuthData() async {
    print('🧹 [AUTH_PROVIDER] Cleaning partial authentication data...');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('auth_token');
      await prefs.setBool('is_authenticated', false);
      print('✅ [AUTH_PROVIDER] Partial data cleaned');
    } catch (e) {
      print('⚠️ [AUTH_PROVIDER] Error cleaning partial data: $e');
    }
  }

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
  Future<bool> login(String email, String password) async {
    print('🔄 [AUTH_PROVIDER] Starting login process for: $email');
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
        
        print('✅ [AUTH_PROVIDER] Login successful for user: ${_user!.id}');
        print('   - Email: ${_user!.email}');
        print('   - Phone: ${_user!.phoneNumber}');
        print('   - Billing Address: ${_user!.billingAddress}');
        print('   - Date of Birth: ${_user!.dateOfBirth}');

        // Store authentication data in SharedPreferences (legacy support)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', _user!.email);
        await prefs.setString('auth_token', token);
        await prefs.setBool('is_authenticated', true);

        print('✅ [AUTH_PROVIDER] Authentication data stored in SharedPreferences');
        _setLoading(false);
        return {'success': true};
      } else {
        print('❌ [AUTH_PROVIDER] Login failed: Invalid response from server');
        _setError('Invalid email or password');
        _setLoading(false);
        return {'success': false, 'message': 'Invalid email or password'};
      }
    } catch (e) {
      print('❌ [AUTH_PROVIDER] Login error: $e');
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', '')
      };
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
    required String phoneNumber,
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
      print('🔄 [AUTH_PROVIDER] Starting logout process...');
      
      // Call AuthService logout to remove all stored data (token + user data)
      await _authService.logout();
      
      // Also clear AuthProvider-specific SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('auth_token'); // Also remove this legacy token key
      await prefs.setBool('is_authenticated', false);

      print('✅ [AUTH_PROVIDER] All authentication data cleared');

      // Clear internal state
      _user = null;
      _isAuthenticated = false;
      _error = null;
      
      print('✅ [AUTH_PROVIDER] Logout completed successfully');
      notifyListeners();
    } catch (e) {
      print('❌ [AUTH_PROVIDER] Logout failed: $e');
      _setError('Failed to logout');
    }
  }

  // Update profile (legacy method - kept for compatibility)
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

        print('✅ [AUTH_PROVIDER] Profile updated successfully');
        print('   - Phone: ${_user!.phoneNumber}');
        print('   - Billing Address: ${_user!.billingAddress}');

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

  // Comprehensive user profile update method
  Future<bool> updateUserProfile(User updatedUser) async {
    if (_user == null) return false;

    print('🔄 [AUTH_PROVIDER] Updating comprehensive user profile...');
    _setLoading(true);
    _setError(null);

    try {
      final result = await _authService.updateUserProfile(updatedUser);

      if (result['success'] == true && result['user'] != null) {
        _user = result['user'];
        print('✅ [AUTH_PROVIDER] Comprehensive profile updated successfully');
        print('   - Phone: ${_user!.phoneNumber}');
        print('   - Date of Birth: ${_user!.dateOfBirth}');
        print('   - Billing Address: ${_user!.billingAddress}');
        print('   - Billing City: ${_user!.billingCity}');
        print('   - Billing Country: ${_user!.billingCountry}');
        print('   - Emergency Contact: ${_user!.emergencyContactName}');
        
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result['message'] ?? 'Profile update failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('❌ [AUTH_PROVIDER] Comprehensive profile update failed: $e');
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
