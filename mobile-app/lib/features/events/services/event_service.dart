import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';
import '../../../core/config/app_config.dart';

// Get event attendees
Future<List<dynamic>> getEventAttendees(String eventId) async {

  final String baseUrl = AppConfig.baseUrl;
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/events/$eventId/attendees'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['data'] as List<dynamic>;
      } else {
        throw Exception(
            'API Error: ${data['message'] ?? 'No attendees found'}');
      }
    } else {
      throw Exception('Failed to fetch attendees: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Network error: $e');
  }
}

class EventService {
  final String baseUrl = AppConfig.baseUrl;

  EventService() {
    print('🔧 EventService initialized with baseUrl: $baseUrl');
  }

  // Get event attendees
  Future<List<dynamic>> getEventAttendees(String eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/events/$eventId/attendees'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as List<dynamic>;
        } else {
          throw Exception(
              'API Error: ${data['message'] ?? 'No attendees found'}');
        }
      } else {
        throw Exception('Failed to fetch attendees: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get all events
  Future<List<Event>> getAllEvents() async {
    try {
      final url = '$baseUrl/api/events';
      print('🌐 EventService: Making API call to: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          // Don't send Access-Control-Allow-Origin from client; it's a response header set by server.
          // Adding it here causes the browser to include it in the preflight request headers, which
          // leads to: "Request header field access-control-allow-origin is not allowed by Access-Control-Allow-Headers".
        },
      ).timeout(const Duration(seconds: 10));

      print('📡 EventService: Response status code: ${response.statusCode}');
      print('📡 EventService: Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        print('📡 EventService: Response body: ${response.body}');
        final data = jsonDecode(response.body);
        print('📦 EventService: Decoded data: $data');

        if (data['success'] == true) {
          final List<dynamic> eventsJson = data['data'];
          print('✅ EventService: Found ${eventsJson.length} events');

          // Parse each event and log any parsing errors
          final List<Event> events = [];
          for (int i = 0; i < eventsJson.length; i++) {
            try {
              final event = Event.fromJson(eventsJson[i]);
              events.add(event);
              print(
                  '✅ EventService: Successfully parsed event ${i + 1}: ${event.title}');
            } catch (parseError) {
              print(
                  '❌ EventService: Failed to parse event ${i + 1}: $parseError');
              print('❌ EventService: Event data: ${eventsJson[i]}');
            }
          }

          return events;
        } else {
          print(
              '❌ EventService: API returned success=false: ${data['message']}');
          throw Exception('API Error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        print(
            '❌ EventService: HTTP error ${response.statusCode}: ${response.body}');
        throw Exception('Failed to fetch events: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('🚨 EventService Error: $e');
      if (e.toString().contains('Failed to fetch')) {
        print('🚨 This looks like a CORS or network connectivity issue');
        print('🚨 Make sure the backend server is running on port 3000');
        print('🚨 And CORS is properly configured');
      }
      rethrow;
    }
  }

  // Get featured events
  Future<List<Event>> getFeaturedEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/events/featured'),
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
        Uri.parse('$baseUrl/api/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Event.fromJson(data['data']);
        } else {
          throw Exception('API Error: ${data['message'] ?? 'Event not found'}');
        }
      } else {
        throw Exception(
            'Failed to fetch event details: ${response.statusCode}');
      }
    } catch (e) {
      print('EventService Error: $e'); // Debug log
      throw Exception('Network error: $e');
    }
  }

  // Search events
  Future<List<Event>> searchEvents(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/events/search/${Uri.encodeComponent(query)}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> eventsJson = data['data'];
          return eventsJson.map((json) => Event.fromJson(json)).toList();
        } else {
          throw Exception('API Error: ${data['message'] ?? 'No events found'}');
        }
      } else {
        throw Exception('Failed to search events: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get events by category
  Future<List<Event>> getEventsByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/events/category/$category'),
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
