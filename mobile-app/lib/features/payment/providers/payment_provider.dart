import 'package:flutter/foundation.dart';

class PaymentProvider extends ChangeNotifier {
  bool _isProcessing = false;
  String? _error;
  String? _paymentIntentId;

  // Getters
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  String? get paymentIntentId => _paymentIntentId;

  // Set processing state
  void _setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  // Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Create payment intent
  Future<bool> createPaymentIntent({
    required double amount,
    required String currency,
    required String eventId,
    required String ticketTypeId,
    required int quantity,
  }) async {
    _setProcessing(true);
    _setError(null);

    try {
      // Simulate payment intent creation - replace with actual Stripe service call
      await Future.delayed(const Duration(seconds: 2));
      _paymentIntentId = 'pi_test_${DateTime.now().millisecondsSinceEpoch}';
      _setProcessing(false);
      return true;
    } catch (e) {
      _setError('Failed to create payment intent');
      _setProcessing(false);
      return false;
    }
  }

  // Process payment
  Future<bool> processPayment({required String paymentMethodId}) async {
    _setProcessing(true);
    _setError(null);

    try {
      // Simulate payment processing - replace with actual Stripe service call
      await Future.delayed(const Duration(seconds: 3));
      _setProcessing(false);
      return true;
    } catch (e) {
      _setError('Payment failed. Please try again.');
      _setProcessing(false);
      return false;
    }
  }

  // Clear error
  void clearError() {
    _setError(null);
  }

  // Reset payment state
  void resetPayment() {
    _paymentIntentId = null;
    _error = null;
    _isProcessing = false;
    notifyListeners();
  }
}
