class PayHereConfig {
  // Sandbox Configuration
  static const bool isSandbox = true;

  // Merchant Credentials (Sandbox)
  static const String sandboxMerchantId = "1231652";
  static const String sandboxMerchantSecret =
      "MjI3NzA4MDQ5NzMyODMwNjEwODI0MDQ0NjI3NTg1Mjk0NDcwMzk0MQ==";

  // Production Credentials (Replace with your live credentials)
  static const String productionMerchantId = "YOUR_PRODUCTION_MERCHANT_ID";
  static const String productionMerchantSecret =
      "YOUR_PRODUCTION_MERCHANT_SECRET";

  // URLs
  static const String sandboxNotifyUrl = "https://sandbox.payhere.lk/notify";
  static const String sandboxReturnUrl = "https://sandbox.payhere.lk/return";
  static const String sandboxCancelUrl = "https://sandbox.payhere.lk/cancel";

  static const String productionNotifyUrl = "https://www.payhere.lk/notify";
  static const String productionReturnUrl = "https://www.payhere.lk/return";
  static const String productionCancelUrl = "https://www.payhere.lk/cancel";

  // App Configuration
  static const String appName = "EventBn";
  static const String platform = "mobile";

  // Get current merchant ID based on environment
  static String get merchantId =>
      isSandbox ? sandboxMerchantId : productionMerchantId;

  // Get current merchant secret based on environment
  static String get merchantSecret =>
      isSandbox ? sandboxMerchantSecret : productionMerchantSecret;

  // Get current notify URL based on environment
  static String get notifyUrl =>
      isSandbox ? sandboxNotifyUrl : productionNotifyUrl;

  // Get current return URL based on environment
  static String get returnUrl =>
      isSandbox ? sandboxReturnUrl : productionReturnUrl;

  // Get current cancel URL based on environment
  static String get cancelUrl =>
      isSandbox ? sandboxCancelUrl : productionCancelUrl;

  // Generate unique app ID
  static String generateAppId() =>
      "${appName}_${DateTime.now().millisecondsSinceEpoch}";

  // Currency configuration
  static const String defaultCurrency = "LKR";

  // Country configuration
  static const String defaultCountry = "Sri Lanka";
  static const String defaultCity = "Colombo";
}
