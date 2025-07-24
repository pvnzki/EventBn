import 'package:flutter_stripe/flutter_stripe.dart';
import '../core/config/app_config.dart';

class StripeService {
  static final StripeService _instance = StripeService._internal();
  factory StripeService() => _instance;
  StripeService._internal();

  // Initialize Stripe
  static Future<void> initialize() async {
    Stripe.publishableKey = AppConfig.stripePublishableKey;
    await Stripe.instance.applySettings();
  }

  // Create payment intent
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // This would typically call your backend API to create a payment intent
      // For now, returning a mock response
      return {
        'success': true,
        'client_secret':
            'pi_test_${DateTime.now().millisecondsSinceEpoch}_secret_test',
        'payment_intent_id': 'pi_test_${DateTime.now().millisecondsSinceEpoch}',
        'amount': (amount * 100).toInt(), // Convert to cents
        'currency': currency.toLowerCase(),
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to create payment intent: $e'};
    }
  }

  // Confirm payment
  Future<Map<String, dynamic>> confirmPayment({
    required String clientSecret,
    required String paymentMethodId,
  }) async {
    try {
      final result = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: const BillingDetails(email: 'customer@example.com'),
          ),
        ),
      );

      if (result.status == PaymentIntentsStatus.Succeeded) {
        return {
          'success': true,
          'payment_intent': result.toJson(),
        };
      } else {
        return {
          'success': false,
          'error': 'Payment failed with status: ${result.status}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Payment confirmation failed: $e'};
    }
  }

  // Present payment sheet
  Future<Map<String, dynamic>> presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'error': 'Payment sheet presentation failed: $e',
      };
    }
  }
}
