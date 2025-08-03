import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class EventProvider with ChangeNotifier {
  List<Event> _events = [];
  Event? _selectedEvent;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreEvents = true;

  List<Event> get events => _events;
  Event? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreEvents => _hasMoreEvents;

  // Fetch events
  Future<void> fetchEvents({
    bool refresh = false,
    String? category,
    String? search,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _events.clear();
      _hasMoreEvents = true;
    }

    if (_isLoading || !_hasMoreEvents) return;

    _setLoading(true);
    _error = null;

    try {
      final result = await ApiService.getEvents(
        page: _currentPage,
        limit: 10,
        category: category,
        search: search,
      );

      if (result['success']) {
        final eventsData = result['data'];
        final newEvents = (eventsData['events'] as List)
            .map((json) => Event.fromJson(json))
            .toList();

        if (refresh) {
          _events = newEvents;
        } else {
          _events.addAll(newEvents);
        }

        _currentPage++;
        _hasMoreEvents =
            newEvents.length == 10; // If we get less than 10, no more events
      } else {
        _error = result['error'];
      }
    } catch (e) {
      _error = 'Failed to fetch events: $e';
    }

    _setLoading(false);
    notifyListeners();
  }

  // Fetch single event
  Future<void> fetchEvent(String eventId) async {
    _setLoading(true);
    _error = null;

    try {
      final result = await ApiService.getEvent(eventId);

      if (result['success']) {
        _selectedEvent = Event.fromJson(result['data']);
      } else {
        _error = result['error'];
      }
    } catch (e) {
      _error = 'Failed to fetch event: $e';
    }

    _setLoading(false);
    notifyListeners();
  }

  // Create event
  Future<bool> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required double price,
    required int capacity,
    required String category,
    String? imageUrl,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final eventData = {
        'title': title,
        'description': description,
        'location': location,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'price': price,
        'capacity': capacity,
        'category': category,
        'imageUrl': imageUrl,
      };

      final result = await ApiService.createEvent(eventData);

      if (result['success']) {
        // Add the new event to the beginning of the list
        final newEvent = Event.fromJson(result['data']['event']);
        _events.insert(0, newEvent);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _error = result['error'];
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to create event: $e';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Search events
  Future<void> searchEvents(String query) async {
    await fetchEvents(refresh: true, search: query);
  }

  // Filter events by category
  Future<void> filterByCategory(String category) async {
    await fetchEvents(refresh: true, category: category);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelectedEvent() {
    _selectedEvent = null;
    notifyListeners();
  }
}
