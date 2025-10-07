import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../services/seat_lock_service.dart';

// Extended user profile interface for payment-related data
class PaymentUserProfile {
  final String address;
  final String city;
  final String country;
  final String deliveryAddress;
  final String deliveryCity;
  final String deliveryCountry;

  const PaymentUserProfile({
    required this.address,
    required this.city,
    required this.country,
    required this.deliveryAddress,
    required this.deliveryCity,
    required this.deliveryCountry,
  });

  // Default profile for users who haven't set address details
  static const PaymentUserProfile defaultProfile = PaymentUserProfile(
    address: "Colombo",
    city: "Colombo",
    country: "Sri Lanka",
    deliveryAddress: "Same as billing",
    deliveryCity: "Colombo",
    deliveryCountry: "Sri Lanka",
  );

  // Factory method to create from user preferences
  factory PaymentUserProfile.fromUserData(Map<String, dynamic>? userData) {
    if (userData == null) return defaultProfile;
    
    return PaymentUserProfile(
      address: userData['address'] ?? defaultProfile.address,
      city: userData['city'] ?? defaultProfile.city,
      country: userData['country'] ?? defaultProfile.country,
      deliveryAddress: userData['delivery_address'] ?? defaultProfile.deliveryAddress,
      deliveryCity: userData['delivery_city'] ?? defaultProfile.deliveryCity,
      deliveryCountry: userData['delivery_country'] ?? defaultProfile.deliveryCountry,
    );
  }
}

class PaymentScreen extends StatefulWidget {
  final String eventId;
  final String eventName;
  final String eventDate;
  final String ticketType;
  final int seatCount;
  final List<String> selectedSeats;
  final List<Map<String, dynamic>> selectedSeatData;

  const PaymentScreen({
    super.key,
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    required this.ticketType,
    required this.seatCount,
    required this.selectedSeats,
    required this.selectedSeatData,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final SeatLockService _seatLockService = SeatLockService();
  final AuthService _authService = AuthService();
  bool _locksExtended = false;
  bool _paymentCompleted = false;
  PaymentUserProfile _userProfile = PaymentUserProfile.defaultProfile;
  bool _isLoadingProfile = true;
  
  // Current user information
  String _currentUserName = '';
  String _currentUserEmail = '';
  String _currentUserPhone = '';

  @override
  void dispose() {
    // Release locks if user leaves payment screen without completing
    if (!_paymentCompleted) {
      _releaseSeatLocks();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _extendSeatLocks();
    _loadUserProfile();
  }

  /// Load user profile data for payment
  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoadingProfile = true;
      });

      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null) {
        // Load user information for payment
        setState(() {
          _currentUserName = '${currentUser.firstName} ${currentUser.lastName}'.trim();
          _currentUserEmail = currentUser.email;
          _currentUserPhone = currentUser.phoneNumber ?? '';
          
          // Ensure we have valid names for payment
          if (_currentUserName.isEmpty) {
            _currentUserName = 'User';
          }
        });
        
        final userProfileData = <String, dynamic>{
          // These would come from user profile settings in a real app
          'address': currentUser.billingAddress,
          'city': currentUser.billingCity,    
          'country': currentUser.billingCountry,
          'delivery_address': currentUser.billingAddress,
          'delivery_city': currentUser.billingCity,
          'delivery_country': currentUser.billingCountry,
        };

        setState(() {
          _userProfile = PaymentUserProfile.fromUserData(userProfileData);
          _isLoadingProfile = false;
        });

        print('✅ User profile loaded for payment');
      } else {
        setState(() {
          _currentUserName = 'Guest User';
          _currentUserEmail = '';
          _currentUserPhone = '';
          _userProfile = PaymentUserProfile.defaultProfile;
          _isLoadingProfile = false;
        });
        print('⚠️ No user found, using default profile for payment');
      }
    } catch (e) {
      setState(() {
        _userProfile = PaymentUserProfile.defaultProfile;
        _isLoadingProfile = false;
      });
      print('❌ Error loading user profile: $e');
    }
  }

  /// Extend seat locks when payment screen starts
  Future<void> _extendSeatLocks() async {
    if (_locksExtended) return;
    
    try {
      for (final seatId in widget.selectedSeats) {
        await _seatLockService.extendSeatLock(
          eventId: widget.eventId,
          seatId: seatId,
        );
      }
      _locksExtended = true;
      print('✅ Seat locks extended for payment process');
    } catch (e) {
      print('❌ Failed to extend seat locks: $e');
      // Continue with payment anyway - locks might still be valid
    }
  }

  /// Release seat locks after successful payment
  Future<void> _releaseSeatLocks() async {
    try {
      for (final seatId in widget.selectedSeats) {
        await _seatLockService.releaseSeatLock(
          eventId: widget.eventId,
          seatId: seatId,
        );
      }
      print('✅ Seat locks released after successful payment');
    } catch (e) {
      print('❌ Failed to release seat locks: $e');
      // Don't fail the payment process because of this
    }
  }

  /// Check if user profile is complete for payment processing
  Future<bool> _checkProfileCompletion() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        print('❌ No current user found');
        return false;
      }
      
      print('🔍 Checking profile completion for user: ${currentUser.email}');
      print('📱 Phone: ${currentUser.phoneNumber}');
      print('🏠 Billing Address: ${currentUser.billingAddress}');
      print('🏙️ Billing City: ${currentUser.billingCity}');
      print('🌍 Billing Country: ${currentUser.billingCountry}');
      print('🚨 Emergency Contact Name: ${currentUser.emergencyContactName}');
      print('📞 Emergency Contact Phone: ${currentUser.emergencyContactPhone}');
      
      print('📱 Phone: "${currentUser.phoneNumber}"');
      print('🏠 Address: "${currentUser.billingAddress}"');
      print('🏙️ City: "${currentUser.billingCity}"');
      print('🌍 Country: "${currentUser.billingCountry}"');
      print('📮 Postal: "${currentUser.billingPostalCode}"');
      print('🚨 Emergency Name: "${currentUser.emergencyContactName}"');
      print('☎️ Emergency Phone: "${currentUser.emergencyContactPhone}"');
      
      final hasBillingInfo = currentUser.hasCompleteBillingInfo;
      final hasEmergencyName = currentUser.emergencyContactName?.isNotEmpty == true;
      final hasEmergencyPhone = currentUser.emergencyContactPhone?.isNotEmpty == true;
      
      print('✅ Has billing info: $hasBillingInfo');
      print('✅ Has emergency name: $hasEmergencyName');
      print('✅ Has emergency phone: $hasEmergencyPhone');
      
      // For better UX, we'll require at least billing info and phone number
      // Emergency contact is recommended but not strictly required for payment
      final isComplete = hasBillingInfo;
      print('🎯 Profile completion result: $isComplete');
      
      return isComplete;
    } catch (e) {
      print('❌ Error checking profile completion: $e');
      return false;
    }
  }

  /// Navigate to profile completion or proceed with payment
  Future<void> _proceedWithPayment() async {
    print('🚀 Starting payment process...');
    final isProfileComplete = await _checkProfileCompletion();
    
    if (!isProfileComplete) {
      print('⚠️ Profile incomplete, showing completion dialog');
      // Show profile completion dialog
      final shouldNavigate = await _showProfileCompletionDialog();
      if (shouldNavigate == true) {
        print('👤 Navigating to edit profile screen');
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EditProfileScreen(),
          ),
        );
        
        print('🔄 Returned from edit profile with result: $result');
        
        // If profile was updated, check again and reload user data
        if (result == true) {
          print('✅ Profile was updated, reloading user data...');
          await _loadUserProfile(); // Reload the user data first
          
          final isNowComplete = await _checkProfileCompletion();
          print('🔍 Profile completion after update: $isNowComplete');
          
          if (isNowComplete) {
            print('🎉 Profile now complete, starting payment...');
            startSandboxPayment();
          } else {
            print('❌ Profile still incomplete');
            _showIncompleteProfileSnackBar();
          }
        } else {
          print('❌ Profile update was cancelled or failed');
        }
      } else {
        print('❌ User cancelled profile completion');
      }
    } else {
      print('✅ Profile is complete, proceeding with payment');
      // Profile is complete, proceed with payment
      startSandboxPayment();
    }
  }

  /// Show dialog asking user to complete profile
  Future<bool?> _showProfileCompletionDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Your Profile'),
        content: const Text(
          'To ensure secure payment processing and emergency contact capability, please complete your profile with billing address and emergency contact information.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Complete Profile'),
          ),
        ],
      ),
    );
  }

  void _showIncompleteProfileSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please complete your profile to proceed with payment'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void startSandboxPayment() {
    // Debug PayHere configuration
    print('🔍 [PAYMENT] PayHere Debug Info:');
    print('🔍 [PAYMENT] Merchant ID: "${AppConfig.payhereMerchantId}"');
    print('🔍 [PAYMENT] Merchant Secret: "${AppConfig.payhereMerchantSecret}"');
    print('🔍 [PAYMENT] Notify URL: "${AppConfig.payhereNotifyUrl}"');
    print('🔍 [PAYMENT] Sandbox Mode: ${AppConfig.payhereSandbox}');
    
    // Validate PayHere configuration
    if (AppConfig.payhereMerchantId.isEmpty || AppConfig.payhereMerchantSecret.isEmpty) {
      print('❌ [PAYMENT] PayHere configuration is missing!');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Configuration Error'),
          content: const Text('PayHere payment credentials are not properly configured. Please check your environment variables.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

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

    // Using PayHere configuration from environment variables
    Map<String, dynamic> paymentObject = {
      "sandbox": AppConfig.payhereSandbox,
      "merchant_id": AppConfig.payhereMerchantId,
      "merchant_secret": AppConfig.payhereMerchantSecret,
      "notify_url": AppConfig.payhereNotifyUrl,
      "order_id": orderId,
      "items": "${widget.eventName} - ${widget.ticketType} Tickets",
      "amount": totalPrice,
      "currency": "LKR",
      "first_name": _currentUserName.split(' ').first,
      "last_name": _currentUserName.split(' ').length > 1
          ? _currentUserName.split(' ').last
          : "User",
      "email": _currentUserEmail,
      "phone": _currentUserPhone,
      "address": _userProfile.address,
      "city": _userProfile.city,
      "country": _userProfile.country,
      "delivery_address": _userProfile.deliveryAddress,
      "delivery_city": _userProfile.deliveryCity,
      "delivery_country": _userProfile.deliveryCountry,
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
      final token = await _authService.getStoredToken();
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
          'selectedSeatData': widget.selectedSeatData, // Include seat data for proper seat labels
        }),
      );

      if (response.statusCode == 201) {
        // Payment record saved successfully - now release seat locks
        _paymentCompleted = true;
        await _releaseSeatLocks();
        
        // Parse response to get ticket IDs
        final responseData = jsonDecode(response.body);
        print('🎫 [PAYMENT] Full response: $responseData');
        
        // Extract ticket IDs from the tickets array
        String? ticketId;
        if (responseData['tickets'] != null && responseData['tickets'] is List) {
          final tickets = responseData['tickets'] as List;
          if (tickets.isNotEmpty) {
            // Use the first ticket's ID (for single ticket purchase) or primary ticket
            ticketId = tickets[0]['ticket_id']?.toString();
          }
        }
        
        // Fallback to other possible ID fields
        final bookingId = ticketId ?? 
                         responseData['booking_id']?.toString() ?? 
                         responseData['ticket_id']?.toString() ?? 
                         responseData['id']?.toString() ?? 
                         paymentId; // Last resort fallback
        
        print('🎫 [PAYMENT] Extracted ticket ID: $ticketId');
        print('🎫 [PAYMENT] Final booking ID: $bookingId');
        
        if (mounted) {
          // Navigate to payment success screen
          final bookingData = {
            'eventId': widget.eventId,
            'eventName': widget.eventName,
            'eventDate': widget.eventDate,
            'ticketType': widget.ticketType,
            'selectedSeats': widget.selectedSeats,
            'selectedSeatData': widget.selectedSeatData,
            'totalAmount': totalAmount,
            'paymentMethod': 'payhere',
            'paymentId': paymentId, // PayHere payment ID
            'bookingId': bookingId, // Database ticket ID (UUID)
            'tickets': responseData['tickets'], // Full ticket data
          };
          
          print('🎉 [PAYMENT] Navigating to payment success with data: $bookingData');
          
          // Use go instead of pushReplacementNamed to ensure clean navigation
          context.go('/booking/payment-success', extra: bookingData);
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
    
    if (_isLoadingProfile) {
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
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
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
              onPressed: _isProcessingPayment ? null : _proceedWithPayment,
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
            // Event Details Section
            Text('Event Details',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            _buildSummaryRow('Event', widget.eventName, theme),
            _buildSummaryRow('Date', widget.eventDate, theme),
            _buildSummaryRow('Seats', seatLabels.join(', '), theme),
            
            const SizedBox(height: 16),
            Divider(color: theme.colorScheme.outline.withOpacity(0.3)),
            const SizedBox(height: 16),
            
            // Contact Details Section
            Text('Contact Details',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            _buildSummaryRow('Name', _currentUserName, theme),
            _buildSummaryRow('Email', _currentUserEmail, theme),
            _buildSummaryRow('Phone', _currentUserPhone, theme),
            
            const SizedBox(height: 16),
            Divider(color: theme.colorScheme.outline.withOpacity(0.3)),
            const SizedBox(height: 16),
            
            // Billing Address Section
            Text('Billing Address',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            _buildSummaryRow('Address', _userProfile.address, theme),
            _buildSummaryRow('City', _userProfile.city, theme),
            _buildSummaryRow('Country', _userProfile.country, theme),
            
            const SizedBox(height: 16),
            Divider(color: theme.colorScheme.outline.withOpacity(0.3)),
            const SizedBox(height: 16),
            
            // Total Section
            _buildSummaryRow(
                'Total', 'LKR ${totalPrice.toStringAsFixed(2)}', theme, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: isTotal 
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                  fontSize: isTotal ? 16 : 14)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(
                    color: isTotal 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: isTotal ? 18 : 14)),
          ),
        ],
      ),
    );
  }
}

