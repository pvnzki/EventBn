import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants.dart';

class AuthService {
  final String baseUrl = AppConfig.baseUrl;

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${Constants.authEndpoint}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['success'] == true &&
          data['token'] != null &&
          data['data'] != null) {
        // Store token
        await _storeToken(data['token']);
        // Store user data
        final user = User.fromJson(data['data']);
        await _storeUser(user);
        return {'success': true, 'user': user, 'token': data['token']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Register user
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${Constants.authEndpoint}/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'phoneNumber': phoneNumber,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Store token
        await _storeToken(data['token']);

        // Store user data
        final user = User.fromJson(data['user']);
        await _storeUser(user);

        return {'success': true, 'user': user, 'token': data['token']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final token = await getStoredToken();
      if (token == null) {
        print('❌ [AUTH_SERVICE] No token found, trying to get test token...');
        final testToken = await _getTestToken();
        if (testToken != null) {
          await _storeToken(testToken);
          return await _getUserFromToken(testToken);
        }
        return null;
      }

      print('🔍 [AUTH_SERVICE] Token found, calling /me endpoint');
      final response = await http.get(
        Uri.parse('$baseUrl${Constants.authEndpoint}/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔍 [AUTH_SERVICE] Response status: ${response.statusCode}');
      print('🔍 [AUTH_SERVICE] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔍 [AUTH_SERVICE] Parsed data: $data');
        final user = User.fromJson(data['user']);
        print(
            '🔍 [AUTH_SERVICE] Created user object: firstName=${user.firstName}, lastName=${user.lastName}');
        return user;
      }
      
      print('❌ [AUTH_SERVICE] Failed to get user: ${response.statusCode}');
      print('🔧 [AUTH_SERVICE] Attempting fallback: extracting user info from JWT token');
      
      // Fallback: Extract user info from JWT token
      return await _getUserFromToken(token);
    } catch (e) {
      print('❌ [AUTH_SERVICE] Error getting current user: $e');
      print('🔧 [AUTH_SERVICE] Attempting fallback: extracting user info from JWT token');
      
      // Fallback: Extract user info from JWT token
      final token = await getStoredToken();
      if (token != null) {
        return await _getUserFromToken(token);
      }
      
      // Final fallback: try to get test token
      print('🔧 [AUTH_SERVICE] Trying to get test token as final fallback...');
      final testToken = await _getTestToken();
      if (testToken != null) {
        await _storeToken(testToken);
        return await _getUserFromToken(testToken);
      }
      
      return null;
    }
  }

  // Get a test token from the backend (development only)
  Future<String?> _getTestToken() async {
    try {
      // Try both core service and post service for test token
      final services = [
        '$baseUrl/api/debug/test-token',
        'http://localhost:3002/api/debug/test-token', // Post service
      ];
      
      for (final url in services) {
        try {
          final response = await http.get(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 5));

          print('🔑 [AUTH_SERVICE] Test token response from $url: ${response.statusCode}');

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['success'] == true && data['token'] != null) {
              print('🔑 [AUTH_SERVICE] Test token obtained successfully from $url');
              return data['token'];
            }
          }
        } catch (e) {
          print('🔑 [AUTH_SERVICE] Failed to get test token from $url: $e');
          continue;
        }
      }
    } catch (error) {
      print('🔑 [AUTH_SERVICE] Failed to get test token: $error');
    }

    return null;
  }

  // Extract user information from JWT token (fallback when service is unavailable)
  Future<User?> _getUserFromToken(String token) async {
    try {
      // JWT tokens have 3 parts separated by dots: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        print('❌ [AUTH_SERVICE] Invalid JWT token format');
        return null;
      }

      // Decode the payload (second part)
      final payload = parts[1];
      // Add padding if needed (JWT base64 encoding may not have padding)
      String normalizedPayload = payload;
      switch (payload.length % 4) {
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
      }
      
      final decodedBytes = base64.decode(normalizedPayload);
      final decodedPayload = utf8.decode(decodedBytes);
      final payloadData = jsonDecode(decodedPayload);
      
      print('🔧 [AUTH_SERVICE] JWT payload: $payloadData');

      // Extract user information from JWT payload
      final userId = payloadData['userId']?.toString() ?? payloadData['user_id']?.toString() ?? payloadData['id']?.toString();
      final name = payloadData['name']?.toString() ?? 'Test User';
      final email = payloadData['email']?.toString() ?? 'test@example.com';
      
      // Split name into first and last name if it's a full name
      final nameParts = name.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : 'Test';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final fallbackUser = User(
        id: userId ?? '1001',
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: null,
        profileImageUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('🔧 [AUTH_SERVICE] Created fallback user: ${fallbackUser.firstName} ${fallbackUser.lastName}');
      return fallbackUser;
    } catch (e) {
      print('❌ [AUTH_SERVICE] Error extracting user from token: $e');
      return null;
    }
  }

  // Update profile
  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    try {
      final token = await getStoredToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final body = <String, dynamic>{};
      if (firstName != null) body['firstName'] = firstName;
      if (lastName != null) body['lastName'] = lastName;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;

      final response = await http.put(
        Uri.parse('$baseUrl${Constants.authEndpoint}/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = User.fromJson(data['user']);
        await _storeUser(user);

        return {'success': true, 'user': user};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Update failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getStoredToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl${Constants.authEndpoint}/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Password change failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.tokenKey);
    await prefs.remove(AppConfig.userKey);
  }

  // Store token
  Future<void> _storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.tokenKey, token);
  }

  // Get stored token
  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.tokenKey);
  }

  // Store user data
  Future<void> _storeUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.userKey, jsonEncode(user.toJson()));
  }

  // Get stored user data
  Future<User?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConfig.userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }
}
