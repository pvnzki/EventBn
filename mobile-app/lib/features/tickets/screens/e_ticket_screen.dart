import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/ticket_model.dart';
import '../services/ticket_service.dart';

class ETicketScreen extends StatefulWidget {
  final String ticketId;
  final Ticket? initialTicket; // Optional initial ticket data

  const ETicketScreen({
    super.key,
    required this.ticketId,
    this.initialTicket,
  });

  @override
  State<ETicketScreen> createState() => _ETicketScreenState();
}

class _ETicketScreenState extends State<ETicketScreen> {
  final TicketService _ticketService = TicketService();
  Ticket? _ticket;
  Map<String, dynamic>? _rawTicketData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialTicket != null) {
      _ticket = widget.initialTicket;
      _isLoading = false;
    }
    _fetchTicketDetails();
  }

  Future<void> _fetchTicketDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // First try to get ticket by ticket ID
      var result = await _ticketService.getTicketDetails(widget.ticketId);

      // If that fails, try to get ticket by payment ID
      if (result['success'] != true) {
        result = await _ticketService.getTicketDetailsByPaymentId(widget.ticketId);
      }

      if (result['success'] == true) {
        setState(() {
          _ticket = result['ticket'];
          _rawTicketData = result['rawData'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load ticket';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'E-Ticket',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: colorScheme.onSurface),
            onPressed: _shareTicket,
          ),
          IconButton(
            icon: Icon(Icons.download, color: colorScheme.onSurface),
            onPressed: _downloadTicket,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState(context);
    }

    if (_errorMessage != null) {
      return _buildErrorState(context);
    }

    if (_ticket == null) {
      return _buildErrorState(context, 'Ticket not found');
    }

    return _buildTicketContent(context);
  }

  Widget _buildLoadingState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Loading ticket details...',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, [String? message]) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            message ?? _errorMessage ?? 'Something went wrong',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchTicketDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketContent(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return RefreshIndicator(
      onRefresh: _fetchTicketDetails,
      color: theme.colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight,
        ),
        child: Column(
          children: [
            // Ticket Container
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withValues(alpha: 0.3)
                        : theme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
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
    final colorScheme = theme.colorScheme;
    
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        image: _ticket!.eventImageUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(_ticket!.eventImageUrl),
                fit: BoxFit.cover,
              )
            : null,
        gradient: _ticket!.eventImageUrl.isEmpty
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
              )
            : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                // Event Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event,
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
                        _ticket!.eventTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _ticket!.venue.isNotEmpty ? _ticket!.venue : 'Venue TBA',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
                _buildStatusBadge(),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Date and Time
            Row(
              children: [
                Expanded(
                  child: _buildHeaderInfo(
                    'Date',
                    DateFormat('E, MMM dd').format(_ticket!.eventStartDate),
                  ),
                ),
                Expanded(
                  child: _buildHeaderInfo(
                    'Time',
                    DateFormat('HH:mm').format(_ticket!.eventStartDate),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    String text;
    
    switch (_ticket!.status) {
      case TicketStatus.active:
        backgroundColor = Colors.green;
        text = 'Valid';
        break;
      case TicketStatus.used:
        backgroundColor = Colors.blue;
        text = 'Used';
        break;
      case TicketStatus.cancelled:
        backgroundColor = Colors.red;
        text = 'Cancelled';
        break;
      case TicketStatus.refunded:
        backgroundColor = Colors.orange;
        text = 'Refunded';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
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
            color: Colors.white.withValues(alpha: 0.7),
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
              color: index % 2 == 0 
                  ? theme.colorScheme.outline.withValues(alpha: 0.3) 
                  : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketBody(BuildContext context) {
    final user = _rawTicketData?['user'];
    final payment = _rawTicketData?['payment'];
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Customer Info
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildTicketInfo(
                  context,
                  'Name',
                  user?['name'] ?? 'N/A',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _buildTicketInfo(
                  context,
                  'Phone',
                  user?['phone_number'] ?? 'N/A',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Ticket Details
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildTicketInfo(
                  context,
                  'Ticket Type',
                  _ticket!.ticketTypeName,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _buildTicketInfo(
                  context,
                  'Payment ID',
                  payment?['payment_id']?.substring(0, 8) ?? 'N/A',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Seat and Location
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildTicketInfo(
                  context,
                  'Seat',
                  _rawTicketData?['seat_label'] ?? 'General Admission',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _buildTicketInfo(
                  context,
                  'Venue',
                  _ticket!.venue.isNotEmpty ? _ticket!.venue : 'TBA',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Amount and Purchase Date
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildTicketInfo(
                  context,
                  'Amount',
                  'LKR ${_ticket!.price.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _buildTicketInfo(
                  context,
                  'Purchased',
                  DateFormat('MMM dd, yyyy').format(_ticket!.purchaseDate),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTicketInfo(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildQRCodeSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark 
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerLowest,
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
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // QR Code with better theme awareness
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, // Always white background for QR code readability
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: QrImageView(
              data: _ticket!.qrCode.isNotEmpty 
                  ? _ticket!.qrCode 
                  : 'TICKET:${_ticket!.id}:${_ticket!.eventId}:${_ticket!.userId}',
              version: QrVersions.auto,
              size: 160,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Ticket ID
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _ticket!.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Ticket ID copied to clipboard'),
                  backgroundColor: colorScheme.primary,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Ticket ID: ${_ticket!.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.copy,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      children: [
        // Add to Calendar Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _addToCalendar,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Add to Calendar',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
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
              side: BorderSide(color: colorScheme.primary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              'Go Home',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _shareTicket() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _downloadTicket() {
    // TODO: Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download functionality coming soon!')),
    );
  }

  void _addToCalendar() {
    // TODO: Implement add to calendar functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calendar integration coming soon!')),
    );
  }

  void _navigateToHome(BuildContext context) {
    // Navigate to home screen using GoRouter
    context.go('/home');
  }
}
