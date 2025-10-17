import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../common_widgets/custom_notification.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const PaymentSuccessScreen({
    super.key,
    required this.bookingData,
  });

  String get paymentId => bookingData['paymentId'] ?? '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Debug logging
    print('🎉 [PAYMENT_SUCCESS] Screen loaded with booking data:');
    print('🎉 [PAYMENT_SUCCESS] Event: ${bookingData['eventName']}');
    print('🎉 [PAYMENT_SUCCESS] Payment ID: $paymentId');
    print(
        '🎉 [PAYMENT_SUCCESS] Selected seats: ${bookingData['selectedSeats']}');
    print(
        '🎉 [PAYMENT_SUCCESS] Seat data type: ${bookingData['selectedSeatData'].runtimeType}');
    print('🎉 [PAYMENT_SUCCESS] Total amount: ${bookingData['totalAmount']}');
    print(
        '🎉 [PAYMENT_SUCCESS] Current route: ${GoRouterState.of(context).uri.toString()}');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Success Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Success Title
                    Text(
                      'Payment Successful!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Success Message
                    Text(
                      'Your payment has been successfully done.',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Payment Details Card
                    _buildPaymentDetailsCard(context),

                    const SizedBox(height: 24),

                    // Event Details Card
                    _buildEventDetailsCard(context),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            _buildBottomButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard(BuildContext context) {
    final theme = Theme.of(context);
    final selectedSeats =
        (bookingData['selectedSeats'] as List<String>?) ?? <String>[];
    final seatCount = selectedSeats.length;
    final subtotal = _calculateSubtotal();
    final tax = subtotal * 0.1;
    final total = subtotal + tax;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(context, 'Payment ID', paymentId),
            const SizedBox(height: 12),
            _buildDetailRow(context, 'Date', _getCurrentDate()),
            const SizedBox(height: 12),
            _buildDetailRow(context, 'Seats',
                '$seatCount x ${bookingData['ticketType'] ?? 'Economy'}'),
            const SizedBox(height: 12),
            _buildDetailRow(
                context, 'Amount', 'LKR ${total.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetailsCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Event Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Event Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bookingData['eventName'] ?? 'National Music Festival 2024',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bookingData['eventDate'] ??
                        'Mon, Dec 24 • 18.00 - 23.00 PM',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Grand Park, New York',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // View E-Ticket Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                _navigateToETicket(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 2,
              ),
              child: const Text(
                'View My E-Ticket',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Go to Home Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () {
                _navigateToHome(context);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.primary, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                'Go to Home',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateSubtotal() {
    double total = 0.0;
    final seatDataRaw = bookingData['selectedSeatData'];

    if (seatDataRaw != null && seatDataRaw is List) {
      final seatData = List<Map<String, dynamic>>.from(seatDataRaw.map(
          (item) => item is Map<String, dynamic> ? item : <String, dynamic>{}));

      for (var seat in seatData) {
        total += (seat['price'] ?? 0.0).toDouble();
      }
    } else {
      // Fallback: use total amount from booking data if seat data is not available
      final totalAmount = bookingData['totalAmount'];
      if (totalAmount != null) {
        total = (totalAmount is double)
            ? totalAmount
            : double.tryParse(totalAmount.toString()) ?? 0.0;
      }
    }

    return total;
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  void _navigateToETicket(BuildContext context) {
    try {
      // Extract bookingId from the booking data
      final bookingId = bookingData['bookingId']?.toString();

      if (bookingId == null || bookingId.isEmpty) {
        print(
            '❌ [PAYMENT SUCCESS] No booking ID available for E-ticket navigation');
        CustomNotification.show(
          context,
          message: 'Unable to view ticket. Booking ID not found.',
          type: NotificationType.error,
        );
        return;
      }

      // Validate UUID format (should be 32-36 characters for UUID)
      if (bookingId.length < 30) {
        print(
            '❌ [PAYMENT SUCCESS] Invalid booking ID format: $bookingId (length: ${bookingId.length})');
        CustomNotification.show(
          context,
          message: 'Invalid ticket ID format. Please try again or contact support.',
          type: NotificationType.error,
        );
        return;
      }

      print(
          '🎫 [PAYMENT SUCCESS] Navigating to E-ticket with booking ID: $bookingId');

      // Navigate to E-Ticket screen using GoRouter with the booking ID
      context.pushNamed(
        'e-ticket',
        pathParameters: {'ticketId': bookingId},
        extra: {
          'bookingData': bookingData,
          'paymentId': paymentId,
          'bookingId': bookingId,
          'tickets': bookingData['tickets'], // Pass ticket data if available
        },
      );
    } catch (e) {
      print('❌ [PAYMENT SUCCESS] Error navigating to E-ticket: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error viewing ticket: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToHome(BuildContext context) {
    // Navigate to home screen and clear the navigation stack
    context.goNamed('home');
  }
}
