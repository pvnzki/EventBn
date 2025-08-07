class Constants {
  // API Endpoints
  static const String authEndpoint = '/auth';
  static const String eventsEndpoint = '/events';
  static const String ticketsEndpoint = '/tickets';
  static const String paymentsEndpoint = '/payments';
  static const String usersEndpoint = '/users';

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
