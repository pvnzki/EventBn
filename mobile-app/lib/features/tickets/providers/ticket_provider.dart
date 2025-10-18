import 'package:flutter/foundation.dart';
import '../models/ticket_model.dart';
import '../services/ticket_service.dart';

class TicketProvider extends ChangeNotifier {
  List<Ticket> _tickets = [];
  bool _isLoading = false;
  String? _error;
  final TicketService _ticketService = TicketService();

  // Getters
  List<Ticket> get tickets => _tickets;
  List<Ticket> get upcomingTickets =>
      _tickets.where((t) => t.isUpcoming).toList();
  List<Ticket> get pastTickets => _tickets.where((t) => t.isPast).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Group tickets by payment ID
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
      );
    }).toList()
      ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate)); // Sort by newest first
  }

  // Get upcoming payment groups
  List<PaymentGroup> get upcomingPaymentGroups {
    return paymentGroups.where((group) => 
      group.tickets.any((ticket) => ticket.isUpcoming)
    ).toList();
  }

  // Get past payment groups
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
        // Update local ticket statuses for this payment
        _tickets = _tickets.map((ticket) {
          if (ticket.paymentId == paymentId && !ticket.isCancelled) {
            return Ticket(
              id: ticket.id,
              eventId: ticket.eventId,
              eventTitle: ticket.eventTitle,
              eventImageUrl: ticket.eventImageUrl,
              userId: ticket.userId,
              ticketTypeId: ticket.ticketTypeId,
              ticketTypeName: ticket.ticketTypeName,
              price: ticket.price,
              quantity: ticket.quantity,
              totalAmount: ticket.totalAmount,
              qrCode: ticket.qrCode,
              status: TicketStatus.cancelled,
              purchaseDate: ticket.purchaseDate,
              eventStartDate: ticket.eventStartDate,
              venue: ticket.venue,
              address: ticket.address,
              paymentId: ticket.paymentId,
            );
          }
          return ticket;
        }).toList();
        
        notifyListeners();
        
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
