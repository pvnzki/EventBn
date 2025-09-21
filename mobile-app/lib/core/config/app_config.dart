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
