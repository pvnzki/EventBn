class Constants {
  // Base URL - Change this to your backend URL
  static const String baseUrl = 'http://10.0.2.2:3000'; // Android emulator
  // static const String baseUrl = 'http://localhost:3000'; // iOS simulator
  // static const String baseUrl = 'https://your-production-url.com'; // Production

  // API Endpoints
  static const String apiPrefix = '/api';
  static const String authEndpoint = '$apiPrefix/auth';
  static const String eventsEndpoint = '$apiPrefix/events';
  static const String ticketsEndpoint = '$apiPrefix/tickets';
  static const String paymentsEndpoint = '$apiPrefix/payments';
  static const String usersEndpoint = '$apiPrefix/users';

  // Full API URLs
  static const String loginUrl = '$baseUrl$authEndpoint/login';
  static const String registerUrl = '$baseUrl$authEndpoint/register';
  static const String eventsUrl = '$baseUrl$eventsEndpoint';
  static const String healthUrl = '$baseUrl/health';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxEmailLength = 100;
  static const int maxNameLength = 50;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 8.0;
  static const double largeBorderRadius = 12.0;

  // Error Messages
  static const String networkError =
      'Network error occurred. Please check your connection.';
  static const String serverError =
      'Internal server error. Please try again later.';
  static const String unauthorizedError =
      'You are not authorized to perform this action.';
  static const String validationError =
      'Please check your input and try again.';

  // Success Messages
  static const String loginSuccess = 'Login successful!';
  static const String registrationSuccess = 'Registration successful!';
  static const String ticketPurchaseSuccess = 'Tickets purchased successfully!';
  static const String profileUpdateSuccess = 'Profile updated successfully!';

  // Payment Constants
  static const String currency = 'USD';
  static const List<String> supportedCardTypes = ['visa', 'mastercard', 'amex'];
}
