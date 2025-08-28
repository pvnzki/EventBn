import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentMethodScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> bookingData;

  const PaymentMethodScreen({
    super.key,
    required this.eventId,
    required this.bookingData,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String _selectedPaymentMethod = 'payhere';

  void _proceedToOrderSummary() {
    final updatedData = Map<String, dynamic>.from(widget.bookingData);
    updatedData['paymentMethod'] = _selectedPaymentMethod;
    
    context.push('/booking/${widget.eventId}/order-summary', extra: updatedData);
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Payments',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: theme.colorScheme.onSurface),
            onPressed: () {
              // QR code scanner functionality
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select the payment method you want to use.',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            
            // Payment Methods
            Expanded(
              child: Column(
                children: [
                  _buildPaymentOption(
                    'PayPal',
                    'assets/icons/paypal.png',
                    'paypal',
                    isEnabled: false,
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentOption(
                    'Google Pay',
                    'assets/icons/google_pay.png',
                    'google_pay',
                    isEnabled: false,
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentOption(
                    'Apple Pay',
                    'assets/icons/apple_pay.png',
                    'apple_pay',
                    isEnabled: false,
                  ),
                  const SizedBox(height: 24),
                  
                  // PayHere Option (Enabled)
                  _buildPaymentOption(
                    'PayHere',
                    'assets/icons/payhere.png',
                    'payhere',
                    isEnabled: true,
                  ),
                  const SizedBox(height: 24),
                  
                  // Add New Card Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                      ),
                    ),
                    child: TextButton(
                      onPressed: () {
                        // Add new card functionality
                      },
                      child: const Text(
                        'Add New Card',
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedPaymentMethod.isNotEmpty ? _proceedToOrderSummary : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, String iconPath, String value, {bool isEnabled = true}) {
    final isSelected = _selectedPaymentMethod == value;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? () {
            setState(() {
              _selectedPaymentMethod = value;
            });
          } : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Payment Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getPaymentColor(value),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _getPaymentIcon(value),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Payment Title
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
                
                // Radio Button
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF6366F1) : Colors.grey,
                      width: 2,
                    ),
                    color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPaymentColor(String method) {
    switch (method) {
      case 'paypal':
        return const Color(0xFF0070BA);
      case 'google_pay':
        return const Color(0xFF4285F4);
      case 'apple_pay':
        return Colors.black;
      case 'payhere':
        return const Color(0xFF00A651);
      default:
        return Colors.grey;
    }
  }

  Widget _getPaymentIcon(String method) {
    switch (method) {
      case 'paypal':
        return const Text(
          'P',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        );
      case 'google_pay':
        return const Text(
          'G',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        );
      case 'apple_pay':
        return const Icon(
          Icons.apple,
          color: Colors.white,
          size: 24,
        );
      case 'payhere':
        return const Text(
          'PH',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        );
      default:
        return const Icon(Icons.payment, color: Colors.white);
    }
  }
}
