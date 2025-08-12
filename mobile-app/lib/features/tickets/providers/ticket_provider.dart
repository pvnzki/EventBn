import 'package:flutter/foundation.dart';
import '../models/ticket_model.dart';

class TicketProvider extends ChangeNotifier {
  List<Ticket> _tickets = [];
  bool _isLoading = false;
  String? _error;

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

  // Fetch user tickets
  Future<void> fetchUserTickets(String userId) async {
    _setLoading(true);
    _setError(null);

    try {
      // Simulate API call - replace with actual service call
      await Future.delayed(const Duration(seconds: 1));
      _tickets = []; // Placeholder - will be populated from API
    } catch (e) {
      _setError('Failed to fetch tickets');
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
}
