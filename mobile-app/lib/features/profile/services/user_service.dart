import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/config/app_config.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final String baseUrl = AppConfig.baseUrl;

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      print('👤 [UserService] Fetching user data for ID: $userId');

      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('👤 [UserService] Response status: ${response.statusCode}');
      print('👤 [UserService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          print('✅ [UserService] User data fetched successfully');
          return data['data'];
        } else {
          print('❌ [UserService] Invalid response format: $data');
          return null;
        }
      } else if (response.statusCode == 404) {
        print('❌ [UserService] User not found');
        return null;
      } else {
        print(
            '❌ [UserService] Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ [UserService] Exception occurred: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri =
          Uri.parse('$baseUrl/api/users').replace(queryParameters: queryParams);

      print('👥 [UserService] Fetching users: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> usersData = data['data'];
          return usersData.cast<Map<String, dynamic>>();
        }
      }

      print('❌ [UserService] Failed to fetch users: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ [UserService] Exception occurred: $e');
      return [];
    }
  }
}
