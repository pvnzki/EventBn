import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class ApiService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Headers
  static Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Token management
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static String? getToken() {
    // This is used for immediate token access - you might want to cache it
    // For now, this returns null and we'll use getTokenAsync() for actual checks
    return null; // Use getTokenAsync() for real token checking
  }

  static Future<String?> getTokenAsync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // User data management
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      print('ApiService: Getting token...');
      final token = await getTokenAsync();
      if (token == null) {
        print('ApiService: No token stored');
        return null; // No token stored
      }

      print('ApiService: Token found, verifying with backend...');
      try {
        // Try to verify token with backend
        final response = await http.get(
          Uri.parse('${Constants.baseUrl}${Constants.authEndpoint}/me'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        print('ApiService: Response status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            print('ApiService: Token valid, updating stored user data');
            // Update stored user data
            await saveUserData(data['user']);
            return data['user'];
          }
        }
        
        // If backend verification fails, check locally stored data
        print('ApiService: Backend verification failed, checking local storage...');
        final prefs = await SharedPreferences.getInstance();
        final userDataString = prefs.getString(_userKey);
        if (userDataString != null) {
          print('ApiService: Found local user data');
          return jsonDecode(userDataString);
        }
      } catch (e) {
        print('ApiService: Backend verification error: $e, checking local storage...');
        // If backend is unreachable, check locally stored data
        final prefs = await SharedPreferences.getInstance();
        final userDataString = prefs.getString(_userKey);
        if (userDataString != null) {
          print('ApiService: Found local user data after backend error');
          return jsonDecode(userDataString);
        }
      }
      
      print('ApiService: No valid user data found, clearing stored data');
      // No valid data found, clear everything
      await clearToken();
      return null;
    } catch (e) {
      print('ApiService: getUserData error: $e');
      // On error, clear token and return null
      await clearToken();
      return null;
    }
  }

  // Auth API calls
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(Constants.loginUrl),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save token and user data
        await saveToken(data['token']);
        await saveUserData(data['user']);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(Constants.registerUrl),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'phone': phone,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Save token and user data
        await saveToken(data['token']);
        await saveUserData(data['user']);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Events API calls
  static Future<Map<String, dynamic>> getEvents({
    int page = 1,
    int limit = 10,
    String? category,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;

      final uri = Uri.parse(Constants.eventsUrl).replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to fetch events',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getEvent(String eventId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.eventsUrl}/$eventId'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to fetch event',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> createEvent(
      Map<String, dynamic> eventData) async {
    try {
      final token = await getTokenAsync();
      final headers = _getHeaders(includeAuth: true);
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        Uri.parse(Constants.eventsUrl),
        headers: headers,
        body: jsonEncode(eventData),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to create event',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Health check
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse(Constants.healthUrl),
        headers: _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
