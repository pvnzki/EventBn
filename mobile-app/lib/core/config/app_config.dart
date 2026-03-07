import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io'
    show Platform; // Platform not available on web (guarded by kIsWeb)

class AppConfig {
  // API Configuration
  /// Base URL resolution with platform awareness.
  /// Priority:
  /// 1. Explicit .env BASE_URL
  /// 2. Web: localhost (10.0.2.2 unusable in browser)
  /// 3. Android emulator: 10.0.2.2
  /// 4. Default: localhost
  static String get baseUrl {
    final env = dotenv.env['BASE_URL'];
    if (env != null && env.isNotEmpty) {
      final isAndroid = _isAndroidDevice();
      if (!isAndroid && env.contains('10.0.2.2')) {
        const adjusted = 'http://localhost:3001';
        print(
            '🔧 AppConfig: Non-Android runtime overriding 10.0.2.2 BASE_URL -> $adjusted');
        return adjusted;
      }
      if (kIsWeb && env.contains('10.0.2.2')) {
        const adjusted = 'http://localhost:3001';
        print(
            '🔧 AppConfig: Web runtime overriding 10.0.2.2 BASE_URL -> $adjusted');
        return adjusted;
      }
      print('🔧 AppConfig: Using BASE_URL from .env: $env');
      return env;
    }

    if (kIsWeb) {
      const webUrl = 'http://localhost:3001';
      print('🔧 AppConfig: kIsWeb no env override, using $webUrl');
      return webUrl;
    }

    try {
      if (Platform.isAndroid) {
        const androidEmu = 'http://10.0.2.2:3001';
        print('🔧 AppConfig: Android platform detected, using $androidEmu');
        return androidEmu;
      }
    } catch (_) {
      // Platform not available (web) or other issue; fall through.
    }

    const fallback = 'http://localhost:3001';
    print('🔧 AppConfig: Fallback baseUrl: $fallback');
    return fallback;
  }

  /// Convenience method for building full API path.
  static String api(String path) {
    /// Convenience method for building full API path (ensures single slash between base and path)
    final cleanedBase = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final cleanedPath = path.startsWith('/') ? path : '/$path';
    return '$cleanedBase$cleanedPath';
  }

  static String get postServiceUrl {
    final envVal = dotenv.env['POST_SERVICE_URL'];
    if (envVal != null && envVal.isNotEmpty) {
      final isAndroid = _isAndroidDevice();
      if (!isAndroid && envVal.contains('10.0.2.2')) {
        const adjusted = 'http://localhost:3002';
        print(
            '🔧 AppConfig: Non-Android runtime overriding 10.0.2.2 POST_SERVICE_URL -> $adjusted');
        return adjusted;
      }
      if (kIsWeb && envVal.contains('10.0.2.2')) {
        const adjusted = 'http://localhost:3002';
        print(
            '🔧 AppConfig: Web runtime overriding 10.0.2.2 POST_SERVICE_URL -> $adjusted');
        return adjusted;
      }
      print('🔧 AppConfig: Using POST_SERVICE_URL from .env: $envVal');
      return envVal;
    }
    // Fallback logic parallels baseUrl
    if (kIsWeb) {
      const webUrl = 'http://localhost:3002';
      print('🔧 AppConfig: kIsWeb post service using $webUrl');
      return webUrl;
    }
    try {
      if (Platform.isAndroid) {
        const androidEmu = 'http://10.0.2.2:3002';
        print('🔧 AppConfig: Android platform post service using $androidEmu');
        return androidEmu;
      }
    } catch (_) {}
    const fallback = 'http://localhost:3002';
    print('🔧 AppConfig: Fallback postServiceUrl: $fallback');
    return fallback;
  }

  static String get notificationServiceUrl {
    final envVal = dotenv.env['NOTIFICATION_SERVICE_URL'];
    if (envVal != null && envVal.isNotEmpty) {
      final isAndroid = _isAndroidDevice();
      if (!isAndroid && envVal.contains('10.0.2.2')) {
        const adjusted = 'http://localhost:3003';
        print(
            '🔧 AppConfig: Non-Android runtime overriding 10.0.2.2 NOTIFICATION_SERVICE_URL -> $adjusted');
        return adjusted;
      }
      if (kIsWeb && envVal.contains('10.0.2.2')) {
        const adjusted = 'http://localhost:3003';
        print(
            '🔧 AppConfig: Web runtime overriding 10.0.2.2 NOTIFICATION_SERVICE_URL -> $adjusted');
        return adjusted;
      }
      print('🔧 AppConfig: Using NOTIFICATION_SERVICE_URL from .env: $envVal');
      return envVal;
    }
    if (kIsWeb) {
      const webUrl = 'http://localhost:3003';
      print('🔧 AppConfig: kIsWeb notification service using $webUrl');
      return webUrl;
    }
    try {
      if (Platform.isAndroid) {
        const androidEmu = 'http://10.0.2.2:3003';
        print('🔧 AppConfig: Android platform notification service using $androidEmu');
        return androidEmu;
      }
    } catch (_) {}
    const fallback = 'http://localhost:3003';
    print('🔧 AppConfig: Fallback notificationServiceUrl: $fallback');
    return fallback;
  }

  // Stripe Configuration
  static String get stripePublishableKey =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
  static String get stripeSecretKey => dotenv.env['STRIPE_SECRET_KEY'] ?? '';

  // PayHere Configuration - Environment variables with sandbox fallback
  static String get payhereMerchantId {
    final envValue = dotenv.env['PAYHERE_MERCHANT_ID'];
    print('🔧 AppConfig: PAYHERE_MERCHANT_ID from .env: "$envValue"');

    // Use environment value if available, otherwise fallback to sandbox
    final value =
        (envValue != null && envValue.isNotEmpty) ? envValue : '1231652';
    print('🔧 AppConfig: Final payhereMerchantId: "$value"');
    return value;
  }

  static String get payhereMerchantSecret {
    final envValue = dotenv.env['PAYHERE_MERCHANT_SECRET'];
    print('🔧 AppConfig: PAYHERE_MERCHANT_SECRET from .env: "$envValue"');

    // Use environment value if available, otherwise fallback to sandbox
    final value = (envValue != null && envValue.isNotEmpty)
        ? envValue
        : 'MzM5NDQxMTAzNzM1NzQyODUwOTk0MTMyNjI1MjQxMTI0NDc2Nzk0NA==';
    print('🔧 AppConfig: Final payhereMerchantSecret: "$value"');
    return value;
  }

  static String get payhereNotifyUrl {
    final envValue = dotenv.env['PAYHERE_NOTIFY_URL'];
    print('🔧 AppConfig: PAYHERE_NOTIFY_URL from .env: "$envValue"');

    final value = (envValue != null && envValue.isNotEmpty)
        ? envValue
        : 'https://sandbox.payhere.lk/notify';
    print('🔧 AppConfig: Final payhereNotifyUrl: "$value"');
    return value;
  }

  static bool get payhereSandbox {
    final envValue = dotenv.env['PAYHERE_SANDBOX'];
    print('🔧 AppConfig: PAYHERE_SANDBOX from .env: "$envValue"');

    // Use environment value if available, otherwise default to sandbox mode (true)
    final value = (envValue != null) ? envValue.toLowerCase() == 'true' : true;
    print('🔧 AppConfig: Final payhereSandbox: $value');
    return value;
  }

  // App Configuration
  static const String appName = 'Event Booking App';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';

  // Pagination
  static const int defaultPageSize = 20;

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // INTERNAL HELPERS
  static bool _isAndroidDevice() {
    try {
      return !kIsWeb && Platform.isAndroid;
    } catch (_) {
      return false; // Platform not available (web build)
    }
  }
}
