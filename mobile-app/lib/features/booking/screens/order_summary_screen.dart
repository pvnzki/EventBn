import 'package:flutter/material.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import '../../events/services/event_service.dart';
import '../../events/models/event_model.dart';
import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';

class OrderSummaryScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> bookingData;

  const OrderSummaryScreen({
    super.key,
    required this.eventId,
    required this.bookingData,
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  Event? _event;
  bool _isLoading = true;
  bool _isPaymentProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  Future<void> _loadEventData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final eventService = EventService();
      final event = await eventService.getEventById(widget.eventId);
      
      setState(() {
        _event = event;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  double get _subtotal {
    double total = 0.0;
    final seatData = widget.bookingData['selectedSeatData'] as List<Map<String, dynamic>>? ?? [];
    for (var seat in seatData) {
      total += (seat['price']?.toDouble() ?? 0.0);
    }
    
    // If no seat data, calculate from event pricing
    if (total == 0.0 && _event != null && _event!.ticketTypes.isNotEmpty) {
      final seatCount = widget.bookingData['seatCount'] ?? 1;
      final ticketType = widget.bookingData['ticketType'] ?? 'General';
      
      // Find the matching ticket type or use the first one
      final matchingTicketType = _event!.ticketTypes.firstWhere(
        (type) => type.name.toLowerCase() == ticketType.toLowerCase(),
        orElse: () => _event!.ticketTypes.first,
      );
      
      total = matchingTicketType.price * seatCount;
    }
    
    return total;
  }

  double get _tax => _subtotal * 0.1; // 10% tax
  double get _total => _subtotal + _tax;

  void _proceedToPayment() async {
    if (_event == null || _isPaymentProcessing) return;

    setState(() {
      _isPaymentProcessing = true;
    });

    try {
      // Start PayHere payment directly
      await _startPayHerePayment();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPaymentProcessing = false;
        });
      }
    }
  }

  Future<void> _startPayHerePayment() async {
    // Calculate total price
    double totalPrice = _total;

    // Ensure we have a minimum amount for testing
    if (totalPrice <= 0) {
      totalPrice = 100.0; // Fallback amount for testing
    }

    Map paymentObject = {
      "sandbox": true, // true if using Sandbox Merchant ID
      "merchant_id": "1231652", // PayHere official sandbox merchant ID
      "merchant_secret": "MzM5NDQxMTAzNzM1NzQyODUwOTk0MTMyNjI1MjQxMTI0NDc2Nzk0NA==", // PayHere official sandbox secret
      "notify_url": "https://sandbox.payhere.lk/notify",
      "order_id": "ItemNo12345-${DateTime.now().millisecondsSinceEpoch}",
      "items": "${_event?.title ?? 'Event Ticket'} - ${widget.bookingData['seatCount'] ?? 1} tickets",
      "amount": totalPrice, // Pass as double, not string
      "currency": "LKR",
      "first_name": widget.bookingData['name']?.split(' ').first ?? '',
      "last_name": widget.bookingData['name']?.split(' ').skip(1).join(' ') ?? '',
      "email": widget.bookingData['email'] ?? '',
      "phone": widget.bookingData['phone'] ?? '',
      "address": "No.1, Galle Road",
      "city": "Colombo",
      "country": "Sri Lanka",
      "delivery_address": "No. 46, Galle road, Kalutara South",
      "delivery_city": "Kalutara",
      "delivery_country": "Sri Lanka",
      "custom_1": widget.eventId,
      "custom_2": widget.bookingData['selectedSeats']?.join(',') ?? '',
    };

    // Debug payment object
    print('PayHere Payment Object:');
    paymentObject.forEach((key, value) => print('  $key: $value'));

    // Validate required fields
    if (paymentObject["merchant_id"] == null ||
        paymentObject["amount"] == null ||
        paymentObject["currency"] == null ||
        paymentObject["order_id"] == null) {
      print("❌ Missing required payment parameters");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment configuration error. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isPaymentProcessing = false;
      });
      return;
    }

    PayHere.startPayment(paymentObject, (paymentId) {
      // Payment completed successfully
      _handlePaymentSuccess(paymentId);
    }, (error) {
      // Payment failed
      _handlePaymentError(error);
    }, () {
      // Payment dismissed
      _handlePaymentDismissed();
    });
  }

  void _handlePaymentSuccess(String paymentId) async {
    try {
      // Save payment to backend
      await _savePaymentToBackend(paymentId);
      
      // Navigate to success screen
      if (mounted) {
        context.go('/booking/payment-success', extra: {
          ...widget.bookingData,
          'paymentId': paymentId,
          'eventData': _event?.toJson(),
          'total': _total,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful but failed to save: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _handlePaymentError(String error) {
    if (mounted) {
      setState(() {
        _isPaymentProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handlePaymentDismissed() {
    if (mounted) {
      setState(() {
        _isPaymentProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment was cancelled'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  Future<void> _savePaymentToBackend(String paymentId) async {
    try {
      final authService = AuthService();
      final token = await authService.getStoredToken();
      
      // Ensure selectedSeats is properly formatted
      List<String> selectedSeats = [];
      if (widget.bookingData['selectedSeats'] != null) {
        selectedSeats = List<String>.from(widget.bookingData['selectedSeats']);
      }
      
      // Validate required fields
      if (widget.eventId.isEmpty || _total <= 0 || selectedSeats.isEmpty) {
        throw Exception('Missing required fields: eventId, amount, or selectedSeats');
      }
      
      // Prepare the payment data with correct field names (matching payment_screen.dart)
      final paymentData = {
        'event_id': int.parse(widget.eventId), // Use underscore format
        'payment_id': paymentId, // Use underscore format
        'amount': _total,
        'payment_method': 'payhere', // Use underscore format
        'selected_seats': selectedSeats, // Use underscore format
        'currency': 'LKR',
        'status': 'completed',
        'customerName': widget.bookingData['name'] ?? '',
        'customerEmail': widget.bookingData['email'] ?? '',
        'customerPhone': widget.bookingData['phone'] ?? '',
        'seatCount': widget.bookingData['seatCount'] ?? 1,
        'ticketType': widget.bookingData['ticketType'] ?? 'General',
      };
      
      // Debug log the payment data
      print('Sending payment data to backend: ${jsonEncode(paymentData)}');
      
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/payments'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(paymentData),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('❌ Backend response error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception('Failed to save payment: ${response.body}');
      }
      
      print('✅ Payment saved successfully to backend');
      final responseData = jsonDecode(response.body);
      print('✅ Backend response: $responseData');
    } catch (e) {
      rethrow;
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Review Summary',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading event data',
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!, 
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadEventData,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Card
                      _buildEventCard(),
                      const SizedBox(height: 24),
                      
                      // Contact Information
                      _buildContactInfo(),
                      const SizedBox(height: 24),
                      
                      // Pricing Breakdown
                      _buildPricingBreakdown(),
                      const SizedBox(height: 24),
                      
                      // Payment Method
                      _buildPaymentMethod(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildEventCard() {
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Event Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: _event?.imageUrl != null && _event!.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_event!.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                gradient: _event?.imageUrl == null || _event!.imageUrl.isEmpty
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                      )
                    : null,
              ),
              child: _event?.imageUrl == null || _event!.imageUrl.isEmpty
                  ? const Center(
                      child: Icon(
                        Icons.event,
                        color: Colors.white,
                        size: 32,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Event Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _event?.title ?? widget.bookingData['eventName'] ?? 'Event',
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
                    _event != null 
                        ? '${_formatDateTime(_event!.startDateTime)} - ${_formatDateTime(_event!.endDateTime)}'
                        : widget.bookingData['eventDate'] ?? 'Date TBD',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _event?.venue ?? widget.bookingData['venue'] ?? 'Venue TBD',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    final day = days[dateTime.weekday - 1];
    final month = months[dateTime.month - 1];
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day, $month ${dateTime.day} • $hour:$minute';
  }

  Widget _buildContactInfo() {
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
        child: Column(
          children: [
            _buildInfoRow('Full Name', widget.bookingData['name'] ?? 'Andrew Ainsley'),
            const SizedBox(height: 16),
            _buildInfoRow('Phone', widget.bookingData['phone'] ?? '+1 111 467 378 399'),
            const SizedBox(height: 16),
            _buildInfoRow('Email', widget.bookingData['email'] ?? 'andrew_ainsley@yo...com'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

  Widget _buildPricingBreakdown() {
    final theme = Theme.of(context);
    final selectedSeats = widget.bookingData['selectedSeats'] as List<String>;
    final seatCount = selectedSeats.length;
    
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
          children: [
            _buildPriceRow('$seatCount Seats (${widget.bookingData['ticketType'] ?? 'Economy'})', '\$${_subtotal.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            _buildPriceRow('Tax', '\$${_tax.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildPriceRow(
              'Total',
              '\$${_total.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false}) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod() {
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
            Container(
              width: 40,
              height: 25,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text(
                  'MC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '•••• •••• •••• 4679',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                context.pop(); // Go back to payment method selection
              },
              child: Text(
                'Change',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
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
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isPaymentProcessing ? null : _proceedToPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 2,
          ),
          child: _isPaymentProcessing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Processing...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payment, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Pay Now - LKR ${_total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
