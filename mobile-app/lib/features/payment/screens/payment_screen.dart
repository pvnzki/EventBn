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
  bool _isProcessingPayment = false;

  Future<void> _processPayment() async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Get auth token
      final token = await AuthService().getStoredToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      // Calculate total amount
      final totalAmount = widget.selectedSeatData.fold(0.0, (sum, seat) => sum + (seat['price'] as num).toDouble());

      // Create payment
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'event_id': widget.eventId,
          'amount': totalAmount,
          'payment_method': 'card',
          'selected_seats': widget.selectedSeats,
        }),
      );

      if (response.statusCode == 201) {
        final paymentData = jsonDecode(response.body);
        
        if (mounted) {
          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Row(
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
                  Text('🎉 Your tickets have been successfully booked!'),
                  const SizedBox(height: 12),
                  Text('Event: ${widget.eventName}'),
                  Text('Date: ${widget.eventDate}'),
                  Text('Seats: ${widget.selectedSeats.join(', ')}'),
                  const SizedBox(height: 8),
                  Text('Payment ID: ${paymentData['payment']['payment_id']}', 
                       style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text('Total: ₹${totalAmount.toStringAsFixed(2)}', 
                       style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
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
        throw Exception('Payment failed: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Payment Failed'),
            content: Text('Error: ${e.toString()}'),
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
              onPressed: _isProcessingPayment ? null : _processPayment,
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
            _buildSummaryRow('Total', '\u20B9${totalPrice.toStringAsFixed(0)}', theme),
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
