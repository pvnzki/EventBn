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
      print('🔄 [AUTH_SERVICE] Logging in user: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl${Constants.authEndpoint}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('🔄 [AUTH_SERVICE] Login response status: ${response.statusCode}');
      print('🔄 [AUTH_SERVICE] Login response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('🔍 [AUTH_SERVICE] Response data: $data');
        print('🔍 [AUTH_SERVICE] success: ${data['success']}');
        print('🔍 [AUTH_SERVICE] requiresTwoFactor: ${data['requiresTwoFactor']}');
        
        // Check if 2FA is required (even if success is false)
        if (data['requiresTwoFactor'] == true) {
          print('🔐 [AUTH_SERVICE] Two-factor authentication required');
          print('🔐 [AUTH_SERVICE] twoFactorMethod: ${data['twoFactorMethod']}');
          return {
            'success': false,
            'requiresTwoFactor': true,
            'twoFactorMethod': data['twoFactorMethod'] ?? 'app',
            'message': data['message'] ?? '2FA required',
            'email': email,
            'password': password, // Temporarily store for 2FA verification
          };
        }
        
        // Only check success=true for normal login
        if (data['success'] == true) {
          // Backend may return user under 'data' or 'user'. Handle both.
          final token = data['token'];
          final dynamic userPayload = data['data'] ?? data['user'];

          if (token == null) {
            print('❌ [AUTH_SERVICE] Login succeeded but token missing in response');
            return {'success': false, 'message': 'Token missing in response'};
          }

          if (userPayload == null || userPayload is! Map<String, dynamic>) {
            print('❌ [AUTH_SERVICE] Login succeeded but user payload missing/invalid: $userPayload');
            return {'success': false, 'message': 'User data missing in response'};
          }

          // Store token and user
          await _storeToken(token);
          final user = User.fromJson(Map<String, dynamic>.from(userPayload));
          await _storeUser(user);

          print('✅ [AUTH_SERVICE] Login successful for: ${user.email}');
          return {'success': true, 'user': user, 'token': token};
        } else {
          print('❌ [AUTH_SERVICE] Login failed: ${data['message']}');
          return {'success': false, 'message': data['message'] ?? 'Login failed'};
        }
      } else {
        print('❌ [AUTH_SERVICE] Non-200 response: ${response.statusCode}');
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      print('❌ [AUTH_SERVICE] Login error: $e');
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Register user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      print('🔄 [AUTH_SERVICE] Registering user: $email');
      
      final requestBody = {
        'name': name,
        'email': email,
        'password': password,
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
      };
      
      print('🔄 [AUTH_SERVICE] Request body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl${Constants.authEndpoint}/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('🔄 [AUTH_SERVICE] Response status: ${response.statusCode}');
      print('🔄 [AUTH_SERVICE] Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        // Backend may return user under 'data' or 'user'. Handle both.
        final token = data['token'];
        final dynamic userPayload = data['data'] ?? data['user'];

        if (token == null) {
          print('❌ [AUTH_SERVICE] Registration succeeded but token missing in response');
          return {'success': false, 'message': 'Token missing in response'};
        }

        if (userPayload == null || userPayload is! Map<String, dynamic>) {
          print('❌ [AUTH_SERVICE] Registration succeeded but user payload missing/invalid: $userPayload');
          return {'success': false, 'message': 'User data missing in response'};
        }

        // Store token and user
        await _storeToken(token);
        final user = User.fromJson(Map<String, dynamic>.from(userPayload));
        await _storeUser(user);

        print('✅ [AUTH_SERVICE] Registration successful for: ${user.email}');
        return {'success': true, 'user': user, 'token': token};
      } else {
        print('❌ [AUTH_SERVICE] Registration failed: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      print('❌ [AUTH_SERVICE] Registration error: $e');
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      // First, try to get user from local storage (most complete data)
      final storedUser = await getStoredUser();
      if (storedUser != null) {
        print('✅ [AUTH_SERVICE] Found complete user data in local storage');
        return storedUser;
      }

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
        final dynamic userPayload = data['user'] ?? data['data'];
        if (userPayload == null || userPayload is! Map<String, dynamic>) {
          print('❌ [AUTH_SERVICE] /me returned invalid user payload: $userPayload');
        } else {
          final user = User.fromJson(Map<String, dynamic>.from(userPayload));
          await _storeUser(user); // Store the complete user data
          print(
              '🔍 [AUTH_SERVICE] Created user object: firstName=${user.firstName}, lastName=${user.lastName}');
          return user;
        }
      }

      print('❌ [AUTH_SERVICE] Failed to get user: ${response.statusCode}');
      print(
          '🔧 [AUTH_SERVICE] Attempting fallback: extracting user info from JWT token');

      // Fallback: Extract user info from JWT token, but merge with stored data if available
      return await _getUserFromToken(token);
    } catch (e) {
      print('❌ [AUTH_SERVICE] Error getting current user: $e');
      print(
          '🔧 [AUTH_SERVICE] Attempting fallback: extracting user info from JWT token');

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

          print(
              '🔑 [AUTH_SERVICE] Test token response from $url: ${response.statusCode}');

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['success'] == true && data['token'] != null) {
              print(
                  '🔑 [AUTH_SERVICE] Test token obtained successfully from $url');
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
      // First, check if we have any stored user data to merge with
      final storedUser = await getStoredUser();

      // JWT tokens have 3 parts separated by dots: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        print('❌ [AUTH_SERVICE] Invalid JWT token format');
        return storedUser; // Return stored user if JWT is invalid
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
      final userId = payloadData['userId']?.toString() ??
          payloadData['user_id']?.toString() ??
          payloadData['id']?.toString();
      final name = payloadData['name']?.toString() ?? 'Test User';
      final email = payloadData['email']?.toString() ?? 'test@example.com';

      // Split name into first and last name if it's a full name
      final nameParts = name.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : 'Test';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // If we have stored user data, merge with JWT data (keep stored profile data)
      if (storedUser != null && storedUser.id == (userId ?? '1001')) {
        print(
            '🔧 [AUTH_SERVICE] Merging JWT data with stored user profile data');
        final mergedUser = storedUser.copyWith(
          firstName: firstName,
          lastName: lastName,
          email: email,
          updatedAt: DateTime.now(),
        );
        print('🔧 [AUTH_SERVICE] Merged user with complete profile data');
        return mergedUser;
      }

      // Create new fallback user if no stored data available
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

      print(
          '🔧 [AUTH_SERVICE] Created fallback user: ${fallbackUser.firstName} ${fallbackUser.lastName}');
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
        final dynamic userPayload = data['user'] ?? data['data'];
        if (userPayload == null || userPayload is! Map<String, dynamic>) {
          return {
            'success': false,
            'message': 'User data missing in response',
          };
        }
        final user = User.fromJson(Map<String, dynamic>.from(userPayload));
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

  // Comprehensive user profile update with all fields
  Future<Map<String, dynamic>> updateUserProfile(User updatedUser) async {
    try {
      final token = await getStoredToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      print('🔄 [AUTH_SERVICE] Updating user profile in database...');

      // Prepare the data for database update using User's toJson method
      final body = updatedUser.toJson();

      // Remove fields that shouldn't be updated via profile endpoint
      body.remove('user_id');
      body.remove('id');
      body.remove('email'); // Email updates should go through separate endpoint
      body.remove('created_at');
      body.remove('updated_at');

      print('🔍 [AUTH_SERVICE] Sending profile data: $body');

      final response = await http.put(
        Uri.parse(
            '$baseUrl${Constants.authEndpoint}/profile'), // Use the new auth profile endpoint
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print(
          '🔍 [AUTH_SERVICE] Profile update response: ${response.statusCode}');
      print('🔍 [AUTH_SERVICE] Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ [AUTH_SERVICE] Basic profile updated in database');

        // Store the complete user data locally (including additional fields)
        await _storeUser(updatedUser);
        print('✅ [AUTH_SERVICE] Complete profile stored locally');

        return {'success': true, 'user': updatedUser};
      } else {
        final data = jsonDecode(response.body);
        print(
            '❌ [AUTH_SERVICE] Database update failed: ${data['message'] ?? 'Unknown error'}');

        // Fallback: Store locally only
        await _storeUser(updatedUser);
        print('⚠️ [AUTH_SERVICE] Stored locally as fallback');

        return {
          'success': true,
          'user': updatedUser,
          'warning': 'Saved locally only'
        };
      }
    } catch (e) {
      print('❌ [AUTH_SERVICE] Error updating user profile: $e');

      // Fallback: Store locally only
      try {
        await _storeUser(updatedUser);
        print('⚠️ [AUTH_SERVICE] Stored locally as fallback after error');
        return {
          'success': true,
          'user': updatedUser,
          'warning': 'Saved locally only due to network error'
        };
      } catch (localError) {
        return {
          'success': false,
          'message': 'Failed to save profile: $localError'
        };
      }
    }
  }

  // Update profile image with Cloudinary URL
  Future<Map<String, dynamic>> updateProfileImage({
    required String imageUrl,
  }) async {
    try {
      final token = await getStoredToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final user = await getStoredUser();
      if (user == null) {
        return {'success': false, 'message': 'User not found'};
      }

      print('🔄 [AUTH_SERVICE] Updating profile image...');

      final body = {
        'avatarUrl': imageUrl,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/api/users/${user.id}/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print(
          '🔍 [AUTH_SERVICE] Profile image update response: ${response.statusCode}');
      print('🔍 [AUTH_SERVICE] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ [AUTH_SERVICE] Profile image updated successfully');

        // Update the local user with new image URL
        final updatedUser = user.copyWith(profileImageUrl: imageUrl);
        await _storeUser(updatedUser);

        return {'success': true, 'user': updatedUser, 'data': data['data']};
      } else {
        final data = jsonDecode(response.body);
        print(
            '❌ [AUTH_SERVICE] Profile image update failed: ${data['message'] ?? 'Unknown error'}');

        return {
          'success': false,
          'message': data['message'] ?? 'Profile image update failed',
        };
      }
    } catch (e) {
      print('❌ [AUTH_SERVICE] Error updating profile image: $e');
      return {'success': false, 'message': 'Network error occurred: $e'};
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
    final userJson = jsonEncode(user.toJson());

    print('📝 Storing user data:');
    print('   Phone: ${user.phoneNumber}');
    print('   Billing Address: ${user.billingAddress}');
    print('   Billing City: ${user.billingCity}');
    print('   Billing Country: ${user.billingCountry}');
    print('   Emergency Name: ${user.emergencyContactName}');
    print('   Emergency Phone: ${user.emergencyContactPhone}');

    await prefs.setString(AppConfig.userKey, userJson);
    print('✅ User data stored successfully');
  }

  // Get stored user data
  Future<User?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConfig.userKey);
    if (userJson != null) {
      final user = User.fromJson(jsonDecode(userJson));

      print('📱 Retrieved user data:');
      print('   Phone: ${user.phoneNumber}');
      print('   Billing Address: ${user.billingAddress}');
      print('   Billing City: ${user.billingCity}');
      print('   Billing Country: ${user.billingCountry}');
      print('   Emergency Name: ${user.emergencyContactName}');
      print('   Emergency Phone: ${user.emergencyContactPhone}');

      return user;
    }
    print('❌ No stored user data found');
    return null;
  }
}
