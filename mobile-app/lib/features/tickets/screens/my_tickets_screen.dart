import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/ticket_provider.dart';
import '../models/ticket_model.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Fetch tickets when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().fetchUserTickets();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  // App Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_available,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Tickets',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Consumer<TicketProvider>(
                    builder: (context, ticketProvider, child) {
                      return IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: theme.colorScheme.onSurface,
                        ),
                        onPressed: ticketProvider.isLoading
                            ? null
                            : () => ticketProvider.refreshTickets(),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  color: theme.colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      spreadRadius: 0,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tab Content
            Expanded(
              child: Consumer<TicketProvider>(
                builder: (context, ticketProvider, child) {
                  if (ticketProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (ticketProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error Loading Tickets',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ticketProvider.error!,
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ticketProvider.refreshTickets(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTicketsList(context, ticketProvider.upcomingTickets, 'upcoming'),
                      _buildTicketsList(context, _getCompletedTickets(ticketProvider.tickets), 'completed'),
                      _buildTicketsList(context, _getCancelledTickets(ticketProvider.tickets), 'cancelled'),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Ticket> _getCompletedTickets(List<Ticket> tickets) {
    return tickets.where((ticket) => 
      ticket.status == TicketStatus.used || 
      (ticket.isPast && ticket.status == TicketStatus.active)
    ).toList();
  }

  List<Ticket> _getCancelledTickets(List<Ticket> tickets) {
    return tickets.where((ticket) => 
      ticket.status == TicketStatus.cancelled || 
      ticket.status == TicketStatus.refunded
    ).toList();
  }

  Widget _buildTicketsList(BuildContext context, List<Ticket> tickets, String tabType) {
    final theme = Theme.of(context);

    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${tabType.capitalize()} Tickets',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyMessage(tabType),
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<TicketProvider>().refreshTickets(),
      child: ListView.builder(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16,
        ),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return _buildModernTicketCard(context, ticket, tabType);
        },
      ),
    );
  }

  String _getEmptyMessage(String tabType) {
    switch (tabType) {
      case 'upcoming':
        return 'Book some events to see your upcoming tickets here';
      case 'completed':
        return 'Your attended events will appear here';
      case 'cancelled':
        return 'Your cancelled bookings will appear here';
      default:
        return 'Your tickets will appear here after purchase';
    }
  }

  Widget _buildModernTicketCard(BuildContext context, Ticket ticket, String tabType) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: isDark ? 10 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image and Title Section
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              image: ticket.eventImageUrl.isNotEmpty 
                ? DecorationImage(
                    image: NetworkImage(ticket.eventImageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticket.eventTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(tabType, ticket.status, theme),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and Time
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatEventDate(ticket.eventStartDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Venue
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ticket.venue.isNotEmpty ? ticket.venue : 'Venue TBA',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action Buttons
                _buildActionButtons(context, ticket, tabType, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String tabType, TicketStatus status, ThemeData theme) {
    Color backgroundColor;
    String text;

    switch (tabType) {
      case 'upcoming':
        backgroundColor = Colors.blue;
        text = 'Paid';
        break;
      case 'completed':
        backgroundColor = Colors.green;
        text = 'Completed';
        break;
      case 'cancelled':
        backgroundColor = Colors.red;
        text = 'Cancelled';
        break;
      default:
        backgroundColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);
        text = 'Unknown';
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

  Widget _buildActionButtons(BuildContext context, Ticket ticket, String tabType, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    
    switch (tabType) {
      case 'upcoming':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showCancelDialog(context, ticket),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.transparent,
                ),
                child: Text(
                  'Cancel Booking',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _navigateToTicketDetails(context, ticket),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text(
                  'View E-Ticket',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );

      case 'completed':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showReviewDialog(context, ticket),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.transparent,
                ),
                child: Text(
                  'Leave a Review',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _navigateToTicketDetails(context, ticket),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text(
                  'View E-Ticket',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );

      case 'cancelled':
      default:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _navigateToTicketDetails(context, ticket),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
            ),
            child: const Text(
              'View Details',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
    }
  }

  String _formatEventDate(DateTime date) {
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final weekday = weekdays[date.weekday % 7];
    final month = months[date.month - 1];
    final day = date.day;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    
    return '$weekday, $month $day • $hour:$minute PM';
  }

  void _showCancelDialog(BuildContext context, Ticket ticket) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel Booking',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this event?',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            Text(
              'Only 80% of funds will be returned to your account according to our policy.',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'No, Don\'t Cancel',
              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showCancelReasonDialog(context, ticket);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCancelReasonDialog(BuildContext context, Ticket ticket) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    String? selectedReason;
    final TextEditingController otherReasonController = TextEditingController();

    final List<String> cancelReasons = [
      'I have another event, so it collides',
      'I\'m sick, can\'t come',
      'I have an urgent need',
      'I have no transportation to come',
      'I have no friends to come',
      'I want to book another event',
      'I just want to cancel',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              ),
              Text(
                'Cancel Booking',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please select the reason for cancellation:',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                const SizedBox(height: 16),
                ...cancelReasons.map((reason) => RadioListTile<String>(
                  title: Text(
                    reason,
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setState(() {
                      selectedReason = value;
                    });
                  },
                  activeColor: colorScheme.primary,
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return colorScheme.primary;
                    }
                    return colorScheme.onSurface.withValues(alpha: 0.5);
                  }),
                )),
                const SizedBox(height: 16),
                Text(
                  'Others',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: otherReasonController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Others reason...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        selectedReason = 'Other: $value';
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedReason != null ? () {
                  Navigator.of(context).pop();
                  _showCancelSuccessDialog(context);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Cancel Booking',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelSuccessDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Animation
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: colorScheme.onPrimary,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You have successfully canceled the event. 80% of the funds will be returned to your account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Refresh tickets
                  context.read<TicketProvider>().refreshTickets();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewDialog(BuildContext context, Ticket ticket) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Leave a Review',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How was your experience at ${ticket.eventTitle}?',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            // Star rating could be implemented here
            const Text('⭐⭐⭐⭐⭐'),
            const SizedBox(height: 16),
            TextField(
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Write your review...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Submit review
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Review submitted successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text('Submit Review'),
          ),
        ],
      ),
    );
  }

  void _navigateToTicketDetails(BuildContext context, Ticket ticket) {
    // Navigate to ticket details/QR code screen
    context.pushNamed(
      'e-ticket',
      pathParameters: {'ticketId': ticket.id},
      extra: {
        'ticket': ticket,
      },
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
