import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/event_model.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants.dart';

class EventService {
  final String baseUrl = AppConfig.baseUrl;

  // Get all events
  Future<List<Event>> getAllEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${Constants.eventsEndpoint}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> eventsJson = data['events'];
        return eventsJson.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch events');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get featured events
  Future<List<Event>> getFeaturedEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${Constants.eventsEndpoint}/featured'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> eventsJson = data['events'];
        return eventsJson.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch featured events');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get event by ID
  Future<Event> getEventById(String eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${Constants.eventsEndpoint}/$eventId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Event.fromJson(data['event']);
      } else {
        throw Exception('Failed to fetch event details');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Search events
  Future<List<Event>> searchEvents(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${Constants.eventsEndpoint}/search?q=$query'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> eventsJson = data['events'];
        return eventsJson.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search events');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get events by category
  Future<List<Event>> getEventsByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${Constants.eventsEndpoint}/category/$category'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> eventsJson = data['events'];
        return eventsJson.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch events by category');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
