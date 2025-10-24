import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';
import '../../../core/config/app_config.dart';
import '../../auth/services/auth_service.dart';

// Get event attendees (standalone function - kept for backward compatibility)
Future<List<dynamic>> getEventAttendees(String eventId) async {
  final String baseUrl = AppConfig.baseUrl;
  try {
    final auth = AuthService();
    final token = await auth.getStoredToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse('$baseUrl/api/events/$eventId/attendees'),
      headers: headers,
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
  late final String baseUrl;
  final http.Client? _client;
  final AuthService? _authService;

  // DI constructor for testing
  EventService({http.Client? client, String? baseUrl, AuthService? authService})
      : _client = client,
        _authService = authService,
        baseUrl = baseUrl ?? AppConfig.baseUrl {
    print('🔧 EventService initialized with baseUrl: ${this.baseUrl}');
  }

  // Get http client (injected or default)
  http.Client get client => _client ?? http.Client();

  // Get auth service (injected or default)
  AuthService get authService => _authService ?? AuthService();

  // Get event attendees
  Future<List<dynamic>> getEventAttendees(String eventId) async {
    try {
      final token = await authService.getStoredToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      final response = await client.get(
        Uri.parse('$baseUrl/api/events/$eventId/attendees'),
        headers: headers,
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

      final token = await authService.getStoredToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await client
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

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
        print('🚨 This looks like a network connectivity or authorization issue');
        print('🚨 Make sure the backend server is running on port 3001');
        print('🚨 Ensure you are logged in and a valid token is stored');
      }
      rethrow;
    }
  }

  // Get featured events
  Future<List<Event>> getFeaturedEvents() async {
    try {
      final token = await authService.getStoredToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final response = await client.get(
        Uri.parse('$baseUrl/api/events/featured'),
        headers: headers,
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
      final token = await authService.getStoredToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final response = await client.get(
        Uri.parse('$baseUrl/api/events/$eventId'),
        headers: headers,
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
      final token = await authService.getStoredToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final response = await client.get(
        Uri.parse('$baseUrl/api/events/search/${Uri.encodeComponent(query)}'),
        headers: headers,
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
      final token = await authService.getStoredToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final response = await client.get(
        Uri.parse('$baseUrl/api/events/category/$category'),
        headers: headers,
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
