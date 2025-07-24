import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class EventProvider extends ChangeNotifier {
  final EventService _eventService = EventService();

  List<Event> _events = [];
  List<Event> _featuredEvents = [];
  Event? _currentEvent;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Event> get events => _events;
  List<Event> get featuredEvents => _featuredEvents;
  Event? get currentEvent => _currentEvent;
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

  // Fetch all events
  Future<void> fetchEvents() async {
    _setLoading(true);
    _setError(null);

    try {
      final fetchedEvents = await _eventService.getAllEvents();
      _events = fetchedEvents;
    } catch (e) {
      _setError('Failed to fetch events');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch featured events
  Future<void> fetchFeaturedEvents() async {
    try {
      final featured = await _eventService.getFeaturedEvents();
      _featuredEvents = featured;
      notifyListeners();
    } catch (e) {
      _setError('Failed to fetch featured events');
    }
  }

  // Fetch event by ID
  Future<void> fetchEventById(String eventId) async {
    _setLoading(true);
    _setError(null);

    try {
      final event = await _eventService.getEventById(eventId);
      _currentEvent = event;
    } catch (e) {
      _setError('Failed to fetch event details');
    } finally {
      _setLoading(false);
    }
  }

  // Search events
  Future<List<Event>> searchEvents(String query) async {
    try {
      return await _eventService.searchEvents(query);
    } catch (e) {
      _setError('Failed to search events');
      return [];
    }
  }

  // Clear current event
  void clearCurrentEvent() {
    _currentEvent = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _setError(null);
  }
}
