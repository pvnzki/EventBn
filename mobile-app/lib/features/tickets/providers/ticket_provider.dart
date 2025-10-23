import 'package:flutter/foundation.dart';
import '../models/ticket_model.dart';
import '../services/ticket_service.dart';

class TicketProvider extends ChangeNotifier {
  List<Ticket> _tickets = [];
  List<PaymentGroup> _upcomingPaymentGroups = [];
  List<Ticket> _completedTickets = [];
  List<Ticket> _cancelledTickets = [];
  int _upcomingCount = 0;
  int _completedCount = 0;
  int _cancelledCount = 0;
  bool _isLoading = false;
  String? _error;
  final TicketService _ticketService = TicketService();

  // Getters
  List<Ticket> get tickets => _tickets;
  List<Ticket> get upcomingTickets =>
      _tickets.where((t) => t.isUpcoming).toList();
  List<Ticket> get pastTickets => _tickets.where((t) => t.isPast).toList();
  List<PaymentGroup> get upcomingPaymentGroups => _upcomingPaymentGroups;
  List<Ticket> get completedTickets => _completedTickets;
  List<Ticket> get cancelledTickets => _cancelledTickets;
  int get upcomingCount => _upcomingCount;
  int get completedCount => _completedCount;
  int get cancelledCount => _cancelledCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Group tickets by payment ID (fallback for backward compatibility)
  List<PaymentGroup> get paymentGroups {
    final Map<String, List<Ticket>> groupedTickets = {};
    
    for (final ticket in _tickets) {
      if (ticket.paymentId.isNotEmpty) {
        groupedTickets.putIfAbsent(ticket.paymentId, () => []);
        groupedTickets[ticket.paymentId]!.add(ticket);
      }
    }

    return groupedTickets.entries.map((entry) {
      final tickets = entry.value;
      final firstTicket = tickets.first;
      
      return PaymentGroup(
        paymentId: entry.key,
        tickets: tickets,
        totalAmount: tickets.fold(0.0, (sum, ticket) => sum + ticket.totalAmount),
        purchaseDate: firstTicket.purchaseDate,
        paymentMethod: 'Card', // This should come from payment data
        paymentStatus: 'Completed', // This should come from payment data
        eventTitle: firstTicket.eventTitle,
        eventStartTime: firstTicket.eventStartDate,
        eventVenue: firstTicket.venue,
        eventLocation: firstTicket.address,
        coverImageUrl: firstTicket.eventImageUrl,
        ticketCount: tickets.length,
        canCancel: false, // Will be determined by backend
      );
    }).toList()
      ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate)); // Sort by newest first
  }

  // Get past payment groups (fallback)
  List<PaymentGroup> get pastPaymentGroups {
    return paymentGroups.where((group) => 
      group.tickets.every((ticket) => ticket.isPast)
    ).toList();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Fetch user tickets from API
  Future<void> fetchUserTickets() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _ticketService.getUserTickets();
      
      if (result['success'] == true) {
        _tickets = result['tickets'] ?? [];
        _upcomingPaymentGroups = result['upcoming_payment_groups'] ?? [];
        _completedTickets = result['completed_tickets'] ?? [];
        _cancelledTickets = result['cancelled_tickets'] ?? [];
        _upcomingCount = result['upcoming_count'] ?? 0;
        _completedCount = result['completed_count'] ?? 0;
        _cancelledCount = result['cancelled_count'] ?? 0;
      } else {
        _setError(result['message'] ?? 'Failed to fetch tickets');
      }
    } catch (e) {
      _setError('Failed to fetch tickets: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Add new ticket after purchase
  void addTicket(Ticket ticket) {
    _tickets.add(ticket);
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _setError(null);
  }

  // Refresh tickets
  Future<void> refreshTickets() async {
    await fetchUserTickets();
  }

  // Cancel all tickets for a payment
  Future<Map<String, dynamic>> cancelTicketsByPayment(String paymentId) async {
    print('🎫 TicketProvider: Starting cancellation for payment: $paymentId');
    _setLoading(true);
    _setError(null);

    try {
      final result = await _ticketService.cancelTicketsByPayment(paymentId);
      print('🎫 TicketProvider: Service returned: $result');
      
      if (result['success'] == true) {
        // After successful cancellation, refresh the ticket data to get updated state
        await fetchUserTickets();
        
        return {
          'success': true,
          'message': result['message'] ?? 'Tickets cancelled successfully',
          'cancelledCount': result['cancelledCount'],
        };
      } else {
        _setError(result['message'] ?? 'Failed to cancel tickets');
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to cancel tickets',
        };
      }
    } catch (e) {
      final errorMessage = 'Failed to cancel tickets: ${e.toString()}';
      _setError(errorMessage);
      return {
        'success': false,
        'message': errorMessage,
      };
    } finally {
      _setLoading(false);
    }
  }
}
