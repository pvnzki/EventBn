import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';

class ETicketScreen extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final String paymentId;

  const ETicketScreen({
    super.key,
    required this.bookingData,
    required this.paymentId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Debug: Print the booking data to understand what's being passed
    print('ETicketScreen - bookingData: $bookingData');
    print('ETicketScreen - paymentId: $paymentId');
    print('ETicketScreen - selectedSeats: ${bookingData['selectedSeats']}');
    print('ETicketScreen - selectedSeats type: ${bookingData['selectedSeats'].runtimeType}');
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'E-Ticket',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: theme.colorScheme.onSurface),
            onPressed: _shareTicket,
          ),
          IconButton(
            icon: Icon(Icons.download, color: theme.colorScheme.onSurface),
            onPressed: _downloadTicket,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Ticket Container
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Ticket Header
                  _buildTicketHeader(context),
                  
                  // Dashed Separator
                  _buildDashedSeparator(context),
                  
                  // Ticket Body
                  _buildTicketBody(context),
                  
                  // QR Code Section
                  _buildQRCodeSection(context),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Event Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Event Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookingData['eventName'] ?? 'National Music Festival 2024',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Opacity(
                      opacity: 0.8,
                      child: const Text(
                        'Grand Park, New York',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Date and Time
          Row(
            children: [
              Expanded(
                child: _buildHeaderInfo('Date', bookingData['eventDate'] ?? 'Mon, Dec 24'),
              ),
              Expanded(
                child: _buildHeaderInfo('Time', '18:00 - 23:00'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDashedSeparator(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(
          50,
          (index) => Expanded(
            child: Container(
              height: 1,
              color: index % 2 == 0 ? theme.colorScheme.outline.withOpacity(0.3) : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketBody(BuildContext context) {
    // Safe cast with null check and fallback
    final selectedSeats = (bookingData['selectedSeats'] as List<dynamic>?)
        ?.map((seat) => seat.toString())
        .toList() ?? <String>[];
    final seatCount = selectedSeats.length;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Customer Info
          Row(
            children: [
              Expanded(
                child: _buildTicketInfo(context, 'Name', bookingData['name'] ?? 'Andrew Ainsley'),
              ),
              Expanded(
                child: _buildTicketInfo(context, 'Phone', bookingData['phone'] ?? '+1 111 467 378 399'),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Ticket Details
          Row(
            children: [
              Expanded(
                child: _buildTicketInfo(context, 'Seats', '$seatCount x ${bookingData['ticketType'] ?? 'Economy'}'),
              ),
              Expanded(
                child: _buildTicketInfo(context, 'Payment ID', paymentId),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Seat Numbers
          if (selectedSeats.isNotEmpty) ...[
            _buildTicketInfo(context, 'Seat Numbers', selectedSeats.join(', ')),
            const SizedBox(height: 20),
          ],
          
          // Amount
          _buildTicketInfo(context, 'Total Amount', '\$${_calculateTotal().toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildTicketInfo(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildQRCodeSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Show this QR code at the entrance',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: _generateQRData(),
              version: QrVersions.auto,
              size: 160,
              backgroundColor: theme.colorScheme.surface,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Booking ID: $paymentId',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Add to Calendar Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _addToCalendar,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 2,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 20),
                SizedBox(width: 8),
                Text(
                  'Add to Calendar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Go Home Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => _navigateToHome(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              'Go Home',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateTotal() {
    double subtotal = 0.0;
    // Safe cast with null check and fallback
    final seatData = (bookingData['selectedSeatData'] as List<dynamic>?)
        ?.map((seat) => seat as Map<String, dynamic>? ?? <String, dynamic>{})
        .toList() ?? <Map<String, dynamic>>[];
    for (var seat in seatData) {
      subtotal += (seat['price'] ?? 0.0);
    }
    return subtotal + (subtotal * 0.1); // Including tax
  }

  String _generateQRData() {
    return 'TICKET:$paymentId:${bookingData['eventId']}:${bookingData['name']}';
  }

  void _shareTicket() {
    // Implement share functionality
    print('Share ticket functionality');
  }

  void _downloadTicket() {
    // Implement download functionality
    print('Download ticket functionality');
  }

  void _addToCalendar() {
    // Implement add to calendar functionality
    print('Add to calendar functionality');
  }

  void _navigateToHome(BuildContext context) {
    // Navigate to home screen using GoRouter
    context.go('/home');
  }
}
