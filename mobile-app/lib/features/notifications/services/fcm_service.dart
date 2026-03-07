import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';

/// Top-level handler for background/terminated FCM messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background isolate has no Firebase — must init here
  await Firebase.initializeApp();
  print('📩 [FCM] Background message: ${message.messageId}');
}

/// Manages FCM token lifecycle, permissions, and message handlers.
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  String? _currentToken;

  String? get currentToken => _currentToken;

  /// Initialize FCM: request permission, get token, set up listeners.
  Future<void> initialize() async {
    // Initialize flutter_local_notifications for foreground display
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _localNotifications.initialize(initSettings);

    // Request permission (iOS will show a dialog; Android auto-grants)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('⚠️ [FCM] Notification permission denied');
      return;
    }

    print('✅ [FCM] Permission: ${settings.authorizationStatus}');

    // Get the FCM token
    try {
      _currentToken = await _messaging.getToken();
      print('🔑 [FCM] Token: $_currentToken');
    } catch (e) {
      print('❌ [FCM] Failed to get token: $e');
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      print('🔄 [FCM] Token refreshed');
      _currentToken = newToken;
      _registerTokenWithBackend(newToken);
    });

    // Foreground messages — show in system tray + refresh in-app
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 [FCM] Foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // When user taps a notification (app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('👆 [FCM] Notification tapped (from bg): ${message.data}');
    });

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('🚀 [FCM] App opened from terminated via notification: ${initialMessage.data}');
    }
  }

  /// Show a local notification in the system tray (foreground only).
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'eventbn_notifications', // must match the channel created in MainActivity.kt
      'EventBn Notifications',
      channelDescription: 'Event booking notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  /// Register the current FCM token with the backend (called after login).
  Future<void> registerToken() async {
    if (_currentToken == null) return;
    await _registerTokenWithBackend(_currentToken!);
  }

  /// Send the FCM token to the notification-service backend.
  Future<void> _registerTokenWithBackend(String fcmToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString(AppConfig.tokenKey);
      if (authToken == null) return;

      final baseUrl = AppConfig.notificationServiceUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'token': fcmToken,
          'platform': defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ [FCM] Token registered with backend');
      } else {
        print('❌ [FCM] Token registration failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [FCM] Token registration error: $e');
    }
  }

  /// Unregister the token on logout.
  Future<void> unregisterToken() async {
    if (_currentToken == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString(AppConfig.tokenKey);
      if (authToken == null) return;

      final baseUrl = AppConfig.notificationServiceUrl;
      await http.delete(
        Uri.parse('$baseUrl/api/notifications/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': _currentToken}),
      ).timeout(const Duration(seconds: 10));

      print('✅ [FCM] Token unregistered from backend');
    } catch (e) {
      print('❌ [FCM] Token unregister error: $e');
    }
  }
}
