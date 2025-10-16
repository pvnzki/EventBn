import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // API Configuration
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'] ?? 'http://localhost:3001';
    print('🔧 AppConfig: BASE_URL from .env: ${dotenv.env['BASE_URL']}');
    print('🔧 AppConfig: Final baseUrl: $url');
    return url;
  }

  static String get postServiceUrl {
    final url = dotenv.env['POST_SERVICE_URL'] ?? 'http://localhost:3002';
    print(
        '🔧 AppConfig: POST_SERVICE_URL from .env: ${dotenv.env['POST_SERVICE_URL']}');
    print('🔧 AppConfig: Final postServiceUrl: $url');
    return url;
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
}
