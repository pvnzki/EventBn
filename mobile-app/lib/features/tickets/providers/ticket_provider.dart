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
}
