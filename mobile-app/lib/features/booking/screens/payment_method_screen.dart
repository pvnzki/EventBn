import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

    context.push('/booking/${widget.eventId}/order-summary',
        extra: updatedData);
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
          'Payments',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon:
                Icon(Icons.qr_code_scanner, color: theme.colorScheme.onSurface),
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
                  // PayHere Option (Enabled)
                  _buildPaymentOption(
                    'PayHere',
                    'payhere',
                    isEnabled: true,
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentOption(
                    'Google Pay',
                    'google_pay',
                    isEnabled: false,
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentOption(
                    'Apple Pay',
                    'apple_pay',
                    isEnabled: false,
                  ),
                  const SizedBox(height: 24),

                  // Add New Card Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: TextButton(
                      onPressed: () {
                        // Add new card functionality
                      },
                      child: Text(
                        'Add New Card',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
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
                onPressed: _selectedPaymentMethod.isNotEmpty
                    ? _proceedToOrderSummary
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
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

  Widget _buildPaymentOption(String title, String value,
      {bool isEnabled = true}) {
    final theme = Theme.of(context);
    final isSelected = _selectedPaymentMethod == value;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.dividerColor.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled
              ? () {
                  setState(() {
                    _selectedPaymentMethod = value;
                  });
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Payment Icon
                Container(
                  width: 70,
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: _getPaymentIcon(value),
                  ),
                ),
                const SizedBox(width: 16),

                // Payment Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isEnabled
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      if (!isEnabled) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Coming Soon',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Radio Button
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                      width: 2,
                    ),
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? Center(
                          child: Icon(
                            Icons.check,
                            color: theme.colorScheme.onPrimary,
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

  Widget _getPaymentIcon(String method) {
    switch (method) {
      case 'payhere':
        return Image.asset(
          'assets/icons/payhere_logo.png',
          width: 96,
          height: 64,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if PNG file is not found
            return Container(
              width: 48,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF00A651),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text(
                  'PayHere',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      case 'google_pay':
        return SvgPicture.string(
          '''<svg xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" width="100" height="100" viewBox="0 0 48 48">
<path fill="#cfd8dc" d="M42,37c0,2.762-2.238,5-5,5H11c-2.761,0-5-2.238-5-5V11c0-2.762,2.239-5,5-5h26c2.762,0,5,2.238,5,5	V37z"></path><path fill="#536dfe" d="M37,6H26.463L13.154,42H37c2.762,0,5-2.238,5-5V11C42,8.238,39.762,6,37,6z"></path><path fill="#fafafa" d="M24.34,23.869v3.365h-1.067v-8.31h2.831c0.683-0.014,1.343,0.245,1.833,0.719 c0.496,0.447,0.776,1.086,0.766,1.754c0.014,0.671-0.265,1.316-0.766,1.764c-0.495,0.472-1.106,0.708-1.833,0.707L24.34,23.869 L24.34,23.869z M24.34,19.947v2.901h1.79c0.397,0.012,0.78-0.144,1.056-0.43c0.561-0.545,0.573-1.442,0.028-2.003 c-0.009-0.01-0.019-0.019-0.028-0.028c-0.273-0.292-0.657-0.452-1.056-0.441L24.34,19.947L24.34,19.947z"></path><path fill="#fafafa" d="M31.163,21.362c0.789,0,1.412,0.211,1.868,0.633s0.685,1,0.684,1.734v3.504h-1.021v-0.789h-0.046 c-0.442,0.65-1.03,0.975-1.764,0.975c-0.626,0-1.15-0.186-1.572-0.557c-0.41-0.345-0.642-0.857-0.633-1.392 c0-0.588,0.222-1.056,0.667-1.404c0.445-0.347,1.038-0.522,1.781-0.522c0.634,0,1.156,0.116,1.566,0.348v-0.244 c0.002-0.365-0.159-0.712-0.441-0.945c-0.282-0.255-0.65-0.394-1.03-0.389c-0.596,0-1.068,0.252-1.416,0.755l-0.94-0.592 C29.384,21.734,30.149,21.362,31.163,21.362z M29.782,25.493c-0.001,0.276,0.13,0.535,0.354,0.696 c0.236,0.186,0.529,0.284,0.829,0.278c0.45-0.001,0.882-0.18,1.201-0.499c0.354-0.333,0.53-0.723,0.53-1.172 c-0.333-0.265-0.797-0.398-1.392-0.398c-0.434,0-0.795,0.105-1.085,0.314C29.927,24.925,29.782,25.183,29.782,25.493L29.782,25.493 z"></path><path fill="#fafafa" d="M39.576,21.548l-3.564,8.192H34.91l1.323-2.866l-2.344-5.325h1.16l1.694,4.084h0.023l1.648-4.084 H39.576z"></path><path fill="#4285f4" d="M17.263,23.143c0-0.325-0.027-0.65-0.082-0.971h-4.502v1.839h2.578 c-0.107,0.593-0.451,1.117-0.953,1.451v1.193h1.539C16.744,25.824,17.263,24.596,17.263,23.143z"></path><path fill="#34a853" d="M12.679,27.808c1.288,0,2.373-0.423,3.164-1.152l-1.539-1.193c-0.428,0.29-0.98,0.456-1.625,0.456 c-1.245,0-2.302-0.839-2.68-1.97H8.414v1.23C9.224,26.79,10.875,27.808,12.679,27.808z"></path><path fill="#fbbc04" d="M9.999,23.948c-0.2-0.593-0.2-1.235,0-1.827v-1.23H8.414c-0.678,1.349-0.678,2.938,0,4.287 L9.999,23.948z"></path><path fill="#ea4335" d="M12.679,20.15c0.681-0.011,1.339,0.246,1.831,0.716l0,0l1.362-1.362 c-0.864-0.811-2.009-1.257-3.194-1.243c-1.805,0-3.455,1.018-4.265,2.63l1.585,1.23C10.377,20.99,11.434,20.15,12.679,20.15z"></path>
</svg>''',
          width: 96,
          height: 64,
          fit: BoxFit.contain,
        );
      case 'apple_pay':
        return SvgPicture.string(
          '''<svg viewBox="0 -9 58 58" fill="none" xmlns="http://www.w3.org/2000/svg"><g id="SVGRepo_bgCarrier" stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCarrier"> <rect x="0.5" y="0.5" width="57" height="39" rx="3.5" fill="white" stroke="#F3F3F3"></rect> <path fill-rule="evenodd" clip-rule="evenodd" d="M17.5771 14.9265C17.1553 15.4313 16.4803 15.8294 15.8053 15.7725C15.7209 15.09 16.0513 14.3649 16.4381 13.9171C16.8599 13.3981 17.5982 13.0284 18.1959 13C18.2662 13.7109 17.992 14.4076 17.5771 14.9265ZM18.1888 15.9076C17.5942 15.873 17.0516 16.0884 16.6133 16.2624C16.3313 16.3744 16.0924 16.4692 15.9107 16.4692C15.7068 16.4692 15.4581 16.3693 15.1789 16.2571C14.813 16.1102 14.3947 15.9422 13.956 15.9502C12.9506 15.9645 12.0154 16.5403 11.5021 17.4573C10.4474 19.2915 11.2279 22.0071 12.2474 23.5C12.7467 24.2393 13.3443 25.0498 14.1318 25.0213C14.4783 25.0081 14.7275 24.9012 14.9854 24.7905C15.2823 24.6631 15.5908 24.5308 16.0724 24.5308C16.5374 24.5308 16.8324 24.6597 17.1155 24.7834C17.3847 24.9011 17.6433 25.014 18.0271 25.0071C18.8428 24.9929 19.356 24.2678 19.8553 23.5284C20.394 22.7349 20.6307 21.9605 20.6667 21.843L20.6709 21.8294C20.67 21.8285 20.6634 21.8254 20.6516 21.82C20.4715 21.7366 19.095 21.0995 19.0818 19.391C19.0686 17.957 20.1736 17.2304 20.3476 17.116C20.3582 17.109 20.3653 17.1043 20.3685 17.1019C19.6654 16.0498 18.5685 15.936 18.1888 15.9076ZM23.8349 24.9289V13.846H27.9482C30.0717 13.846 31.5553 15.3246 31.5553 17.4858C31.5553 19.6469 30.0435 21.1398 27.892 21.1398H25.5365V24.9289H23.8349ZM25.5365 15.2962H27.4982C28.9748 15.2962 29.8185 16.0924 29.8185 17.4929C29.8185 18.8934 28.9748 19.6967 27.4912 19.6967H25.5365V15.2962ZM37.1732 23.5995C36.7232 24.4668 35.7318 25.0142 34.6631 25.0142C33.081 25.0142 31.9771 24.0616 31.9771 22.6256C31.9771 21.2038 33.0459 20.3863 35.0217 20.2654L37.1451 20.1374V19.5261C37.1451 18.6232 36.5615 18.1327 35.5209 18.1327C34.6631 18.1327 34.0373 18.5806 33.9107 19.263H32.3779C32.4271 17.827 33.7631 16.782 35.5701 16.782C37.5177 16.782 38.7834 17.8128 38.7834 19.4123V24.9289H37.2084V23.5995H37.1732ZM35.1201 23.6991C34.2131 23.6991 33.6365 23.2583 33.6365 22.5829C33.6365 21.8863 34.192 21.481 35.2537 21.4171L37.1451 21.2962V21.9218C37.1451 22.9597 36.2732 23.6991 35.1201 23.6991ZM44.0076 25.3626C43.3256 27.3033 42.5451 27.9431 40.8857 27.9431C40.7592 27.9431 40.3373 27.9289 40.2388 27.9005V26.5711C40.3443 26.5853 40.6045 26.5995 40.7381 26.5995C41.4904 26.5995 41.9123 26.2796 42.1724 25.4479L42.3271 24.9573L39.4443 16.8886H41.2232L43.2271 23.436H43.2623L45.2662 16.8886H46.9959L44.0076 25.3626Z" fill="#000000"></path> </g></svg>''',
          width: 96,
          height: 64,
          fit: BoxFit.contain,
        );
      default:
        return const Icon(Icons.payment, color: Colors.grey, size: 24);
    }
  }
}
