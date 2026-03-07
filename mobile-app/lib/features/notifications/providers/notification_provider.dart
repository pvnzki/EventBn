import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import '../services/notification_api_service.dart';
import '../services/fcm_service.dart';

/// Notification Provider — ChangeNotifier that polls the Notification Service
/// for new notifications and exposes state to the widget tree.
class NotificationProvider extends ChangeNotifier {
  final NotificationApiService _apiService;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  Timer? _pollTimer;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _currentPage < _totalPages;

  NotificationProvider({NotificationApiService? apiService})
      : _apiService = apiService ?? NotificationApiService();

  /// Start periodic polling for unread count (every 30 seconds).
  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchUnreadCount(),
    );
    // Immediate first fetch
    fetchUnreadCount();

    // Register FCM token and listen for foreground pushes (requires Firebase)
    _initFirebaseListeners();
  }

  /// Safely set up FCM listeners — must not crash if Firebase is unavailable.
  Future<void> _initFirebaseListeners() async {
    try {
      await FcmService().registerToken();
      FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) => fetchUnreadCount(),
        onError: (e) => print('⚠️ [NOTIFICATION_PROVIDER] onMessage error: $e'),
      );
    } catch (e) {
      print('⚠️ [NOTIFICATION_PROVIDER] Firebase not available: $e');
    }
  }

  /// Stop polling (e.g., on logout or dispose).
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Fetch unread count (lightweight — used for the badge).
  Future<void> fetchUnreadCount() async {
    try {
      final count = await _apiService.getUnreadCount();
      if (count != _unreadCount) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (e) {
      // Silently fail — badge just won't update
      print('⚠️ [NOTIFICATION_PROVIDER] fetchUnreadCount error: $e');
    }
  }

  /// Fetch the first page of notifications (pull-to-refresh).
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _apiService.getNotifications(page: 1);

    if (result['success'] == true) {
      _notifications =
          result['notifications'] as List<NotificationModel>? ?? [];
      final pagination = result['pagination'] as Map<String, dynamic>?;
      _currentPage = pagination?['page'] ?? 1;
      _totalPages = pagination?['totalPages'] ?? 1;
      _error = null;
    } else {
      _error = result['message'] as String?;
    }

    _isLoading = false;
    notifyListeners();

    // Also refresh unread count
    fetchUnreadCount();
  }

  /// Load next page (infinite scroll).
  Future<void> loadMore() async {
    if (_isLoading || !hasMore) return;

    _isLoading = true;
    notifyListeners();

    final result =
        await _apiService.getNotifications(page: _currentPage + 1);

    if (result['success'] == true) {
      final moreNotifications =
          result['notifications'] as List<NotificationModel>? ?? [];
      _notifications.addAll(moreNotifications);
      final pagination = result['pagination'] as Map<String, dynamic>?;
      _currentPage = pagination?['page'] ?? _currentPage;
      _totalPages = pagination?['totalPages'] ?? _totalPages;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(int notificationId) async {
    final success = await _apiService.markAsRead(notificationId);
    if (success) {
      final index = _notifications
          .indexWhere((n) => n.notificationId == notificationId);
      if (index != -1) {
        final old = _notifications[index];
        _notifications[index] = NotificationModel(
          notificationId: old.notificationId,
          userId: old.userId,
          title: old.title,
          body: old.body,
          type: old.type,
          data: old.data,
          isRead: true,
          createdAt: old.createdAt,
          updatedAt: DateTime.now(),
        );
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
    }
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    final success = await _apiService.markAllAsRead();
    if (success) {
      _notifications = _notifications.map((n) {
        return NotificationModel(
          notificationId: n.notificationId,
          userId: n.userId,
          title: n.title,
          body: n.body,
          type: n.type,
          data: n.data,
          isRead: true,
          createdAt: n.createdAt,
          updatedAt: DateTime.now(),
        );
      }).toList();
      _unreadCount = 0;
      notifyListeners();
    }
  }

  /// Delete a notification.
  Future<void> deleteNotification(int notificationId) async {
    final success = await _apiService.deleteNotification(notificationId);
    if (success) {
      final wasUnread = _notifications
          .any((n) => n.notificationId == notificationId && !n.isRead);
      _notifications.removeWhere((n) => n.notificationId == notificationId);
      if (wasUnread && _unreadCount > 0) _unreadCount--;
      notifyListeners();
    }
  }

  /// Clear all local state (e.g., on logout).
  void clear() {
    stopPolling();
    _notifications = [];
    _unreadCount = 0;
    _currentPage = 1;
    _totalPages = 1;
    _error = null;
    notifyListeners();

    // Unregister FCM token from backend
    FcmService().unregisterToken();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
