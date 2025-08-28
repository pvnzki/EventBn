import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';

class PaymentScreen extends StatefulWidget {
  final String eventId;
  final String eventName;
  final String eventDate;
  final String ticketType;
  final int seatCount;
  final List<String> selectedSeats;
  final List<Map<String, dynamic>> selectedSeatData;
  final String name;
  final String email;
  final String phone;

  const PaymentScreen({
    super.key,
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    required this.ticketType,
    required this.seatCount,
    required this.selectedSeats,
    required this.selectedSeatData,
    required this.name,
    required this.email,
    required this.phone,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  void startSandboxPayment() {
    // Calculate total price from selected seat data
    double totalPrice = 0.0;
    for (var seatData in widget.selectedSeatData) {
      totalPrice += (seatData['price'] ?? 0.0);
    }

    // Ensure we have a minimum amount for testing
    if (totalPrice <= 0) {
      totalPrice = 100.0; // Fallback amount for testing
    }

    // Generate unique order ID
    String orderId = "ORDER_${DateTime.now().millisecondsSinceEpoch}";

    // Using PayHere's official sandbox test credentials
    Map<String, dynamic> paymentObject = {
      "sandbox": true,
      "merchant_id": "1231652",
      "merchant_secret":
          "MzM5NDQxMTAzNzM1NzQyODUwOTk0MTMyNjI1MjQxMTI0NDc2Nzk0NA==",
      "notify_url": "https://sandbox.payhere.lk/notify",
      "order_id": orderId,
      "items": "${widget.eventName} - ${widget.ticketType} Tickets",
      "amount": totalPrice,
      "currency": "LKR",
      "first_name": widget.name.split(' ').first,
      "last_name": widget.name.split(' ').length > 1
          ? widget.name.split(' ').last
          : "User",
      "email": widget.email,
      "phone": widget.phone,
      "address": "Colombo",
      "city": "Colombo",
      "country": "Sri Lanka",
      "delivery_address": "Same as billing",
      "delivery_city": "Colombo",
      "delivery_country": "Sri Lanka",
      "custom_1": "",
      "custom_2": ""
    };

    print('PayHere paymentObject:');
    paymentObject.forEach((key, value) => print('  $key: $value'));

    // Validate required fields
    if (paymentObject["merchant_id"] == null ||
        paymentObject["amount"] == null ||
        paymentObject["currency"] == null ||
        paymentObject["order_id"] == null) {
      print("❌ Missing required payment parameters");
      return;
    }

    PayHere.startPayment(
      paymentObject,
      (paymentId) {
        print("✅ Payment Success. Payment Id: $paymentId");
        _handlePaymentSuccess(paymentId, totalPrice);
      },
      (error) {
        print("❌ Payment Failed. Error: $error");
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Payment Failed'),
              content: Text('Error: $error'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      },
      () {
        print("⚠️ Payment Dismissed by User");
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Payment Cancelled'),
              content: const Text(
                  'You dismissed the payment gateway before completing payment.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  bool _isProcessingPayment = false;

  Future<void> _handlePaymentSuccess(
      String paymentId, double totalAmount) async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Get auth token
      final token = await AuthService().getStoredToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      // Create payment record in backend
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'event_id': widget.eventId,
          'amount': totalAmount,
          'payment_method': 'payhere',
          'payment_id': paymentId,
          'selected_seats': widget.selectedSeats,
        }),
      );

      if (response.statusCode == 201) {
        // Payment record saved successfully
        if (mounted) {
          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  SizedBox(width: 8),
                  Text('Booking Confirmed!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎉 Your tickets have been successfully booked!'),
                  const SizedBox(height: 12),
                  Text('Event: ${widget.eventName}'),
                  Text('Date: ${widget.eventDate}'),
                  Text('Seats: ${widget.selectedSeats.join(', ')}'),
                  const SizedBox(height: 8),
                  Text('Payment ID: $paymentId',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text('Total: LKR${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog first
                    // Navigate to event details page
                    context.go('/events/${widget.eventId}');
                  },
                  child: const Text('View Event'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception('Failed to save payment record: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Payment Processing Failed'),
            content: Text(
                'Payment was successful but failed to save record: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        title: Text('Payment',
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm and Pay',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 24),
            _buildSummary(theme),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                elevation: 4,
              ),
              onPressed: _isProcessingPayment ? null : startSandboxPayment,
              child: _isProcessingPayment
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Processing...'),
                      ],
                    )
                  : const Text('Pay Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(ThemeData theme) {
    // Calculate total price from selected seat data
    double totalPrice = 0.0;
    List<String> seatLabels = [];

    for (var seatData in widget.selectedSeatData) {
      totalPrice += (seatData['price'] ?? 0.0);
      seatLabels.add(seatData['label'] ?? '');
    }

    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow('Event', widget.eventName, theme),
            _buildSummaryRow('Date', widget.eventDate, theme),
            _buildSummaryRow('Name', widget.name, theme),
            _buildSummaryRow('Email', widget.email, theme),
            _buildSummaryRow('Phone', widget.phone, theme),
            _buildSummaryRow('Seats', seatLabels.join(', '), theme),
            _buildSummaryRow(
                'Total', 'LKR ${totalPrice.toStringAsFixed(2)}', theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
