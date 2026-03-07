import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../models/notification_model.dart';

/// HTTP client for the Notification Service REST API.
///
/// Note: The notification service runs on a separate port (3003) in
/// microservice mode. In monolith mode it proxies through the main gateway.
class NotificationApiService {
  final http.Client? _client;

  NotificationApiService({http.Client? client}) : _client = client;

  http.Client get client => _client ?? http.Client();

  /// Notification service base URL — uses the dedicated config getter
  /// which handles platform detection (physical device, emulator, web).
  String get _notificationBaseUrl => AppConfig.notificationServiceUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.tokenKey);
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Fetch paginated notifications.
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'User not authenticated'};
    }

    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (type != null) 'type': type,
      };

      final uri = Uri.parse('$_notificationBaseUrl/api/notifications')
          .replace(queryParameters: queryParams);

      final response = await client
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<NotificationModel> notifications =
            (body['notifications'] as List)
                .map((n) => NotificationModel.fromJson(n))
                .toList();

        return {
          'success': true,
          'notifications': notifications,
          'pagination': body['pagination'],
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'Session expired'};
      } else {
        return {'success': false, 'message': 'Failed to load notifications'};
      }
    } catch (e) {
      print('❌ [NOTIFICATION_SERVICE] getNotifications error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  /// Get unread notification count.
  Future<int> getUnreadCount() async {
    final token = await _getToken();
    if (token == null) return 0;

    try {
      final response = await client
          .get(
            Uri.parse('$_notificationBaseUrl/api/notifications/unread-count'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['unreadCount'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      print('❌ [NOTIFICATION_SERVICE] getUnreadCount error: $e');
      return 0;
    }
  }

  /// Mark a single notification as read.
  Future<bool> markAsRead(int notificationId) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await client
          .put(
            Uri.parse(
                '$_notificationBaseUrl/api/notifications/$notificationId/read'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ [NOTIFICATION_SERVICE] markAsRead error: $e');
      return false;
    }
  }

  /// Mark all notifications as read.
  Future<bool> markAllAsRead() async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await client
          .put(
            Uri.parse('$_notificationBaseUrl/api/notifications/read-all'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ [NOTIFICATION_SERVICE] markAllAsRead error: $e');
      return false;
    }
  }

  /// Delete a notification.
  Future<bool> deleteNotification(int notificationId) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await client
          .delete(
            Uri.parse(
                '$_notificationBaseUrl/api/notifications/$notificationId'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ [NOTIFICATION_SERVICE] deleteNotification error: $e');
      return false;
    }
  }
}
