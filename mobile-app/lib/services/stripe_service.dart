import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../core/config/app_config.dart';

class StripeService {
  static StripeService? _instance;

  StripeService._internal();

  static StripeService get instance {
    _instance ??= StripeService._internal();
    return _instance!;
  }

  // Initialize Stripe
  static void initialize() {
    Stripe.publishableKey = AppConfig.stripePublishableKey;
  }

  // Create payment intent
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // In a real app, this would call your backend API to create a payment intent
      // For now, we'll simulate the response structure
      return {
        'client_secret':
            'pi_test_${DateTime.now().millisecondsSinceEpoch}_secret_test',
        'id': 'pi_test_${DateTime.now().millisecondsSinceEpoch}',
        'amount': (amount * 100).toInt(), // Stripe uses cents
        'currency': currency,
        'status': 'requires_payment_method',
      };
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }

  // Confirm payment
  Future<PaymentIntent> confirmPayment({
    required String clientSecret,
    required PaymentMethodParams paymentMethodParams,
  }) async {
    try {
      return await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: paymentMethodParams,
      );
    } catch (e) {
      throw Exception('Payment confirmation failed: $e');
    }
  }

  // Create payment method
  Future<PaymentMethod> createPaymentMethod({
    required PaymentMethodParams params,
  }) async {
    try {
      return await Stripe.instance.createPaymentMethod(params: params);
    } catch (e) {
      throw Exception('Failed to create payment method: $e');
    }
  }

  // Present payment sheet
  Future<void> presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      throw Exception('Payment sheet failed: $e');
    }
  }

  // Initialize payment sheet
  Future<void> initPaymentSheet({
    required String paymentIntentClientSecret,
    required String merchantDisplayName,
  }) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: merchantDisplayName,
          style: ThemeMode.system,
        ),
      );
    } catch (e) {
      throw Exception('Failed to initialize payment sheet: $e');
    }
  }
}
