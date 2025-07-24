import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // API Configuration
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'http://localhost:3000/api';

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
