import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/event_model.dart';

class ExploreDataService {
  static final _random = Random();
  static int _currentPage = 0;
  static const int _pageSize = 10;
  static const String baseUrl = 'http://localhost:3001';

  // Cache for API events
  static List<Map<String, dynamic>> _cachedEvents = [];
  static DateTime? _lastFetchTime;
  static const Duration cacheExpiry = Duration(minutes: 5);

  // Fetch events from API
  static Future<List<Map<String, dynamic>>> fetchEventsFromAPI() async {
    try {
      final now = DateTime.now();
      if (_cachedEvents.isNotEmpty && 
          _lastFetchTime != null && 
          now.difference(_lastFetchTime!).compareTo(cacheExpiry) < 0) {
        return _cachedEvents;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/events'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _cachedEvents = data.map((event) => {
          'id': event['event_id'].toString(),
          'name': event['title'] ?? 'Untitled Event',
          'imageUrl': event['image'] ?? 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800',
          'location': event['displayLocation'] ?? event['location'] ?? 'TBA',
          'date': event['start_time'] ?? DateTime.now().toIso8601String(),
          'category': event['category'] ?? 'General',
          'price': (event['price'] ?? 25).toDouble(),
          'badge': _generateBadge(event['category']),
          'attendees': _generateAttendees(),
          'isVerified': _random.nextBool(),
          'rating': _generateRating(),
          'description': event['description'] ?? 'No description available',
          'venue': event['venue'] ?? 'TBA',
        }).cast<Map<String, dynamic>>().toList();
        
        _lastFetchTime = now;
        return _cachedEvents;
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching events from API: $e');
      // Return fallback data if API fails
      return _getFallbackEvents();
    }
  }

  // Generate badge based on category
  static String _generateBadge(String? category) {
    final badges = {
      'music': ['Trending', 'Hot', 'Popular'],
      'tech': ['Featured', 'Innovation', 'Premium'],
      'food': ['New', 'Tasty', 'Local'],
      'sports': ['Exciting', 'Championship', 'Live'],
      'art': ['Creative', 'Inspiring', 'Unique'],
      'comedy': ['Hilarious', 'Stand-up', 'Fun'],
    };
    
    final categoryBadges = badges[category?.toLowerCase()] ?? ['Event'];
    return categoryBadges[_random.nextInt(categoryBadges.length)];
  }

  // Generate random attendees count
  static int _generateAttendees() {
    return 50 + _random.nextInt(2000);
  }

  // Generate random rating
  static double _generateRating() {
    return 3.5 + (_random.nextDouble() * 1.5);
  }

  // Fallback events in case API fails
  static List<Map<String, dynamic>> _getFallbackEvents() {
    return [
      {
        'id': '1',
        'name': 'Summer Music Festival 2025',
        'imageUrl': 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800',
        'location': 'Central Park, NYC',
        'date': '2025-07-15T18:00:00Z',
        'category': 'Music',
        'price': 89.99,
        'badge': 'Trending',
        'attendees': 2500,
        'isVerified': true,
        'rating': 4.8,
        'description': 'An amazing summer music festival featuring top artists',
        'venue': 'Central Park Main Stage',
      },
      {
        'id': '2',
        'name': 'Tech Innovation Summit',
        'imageUrl': 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
        'location': 'Silicon Valley, CA',
        'date': '2025-08-20T09:00:00Z',
        'category': 'Tech',
        'price': 299.99,
        'badge': 'Featured',
        'attendees': 1200,
        'isVerified': true,
        'rating': 4.9,
        'description': 'The latest in technology and innovation',
        'venue': 'Convention Center',
      },
      {
        'id': '3',
        'name': 'Street Food Carnival',
        'imageUrl': 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
        'location': 'Downtown LA',
        'date': '2025-06-10T12:00:00Z',
        'category': 'Food',
        'price': 25.00,
        'badge': 'New',
        'attendees': 800,
        'isVerified': false,
        'rating': 4.2,
        'description': 'Taste the best street food from around the world',
        'venue': 'Downtown Plaza',
      },
    ];
  }

  // Get paginated events
  static Future<List<ExploreEvent>> getExploreEvents({int page = 0}) async {
    final allEvents = await fetchEventsFromAPI();
    
    final startIndex = page * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, allEvents.length);
    
    if (startIndex >= allEvents.length) {
      return [];
    }
    
    final pageEvents = allEvents.sublist(startIndex, endIndex);
    
    return pageEvents.map((eventData) => ExploreEvent.fromJson(eventData)).toList();
  }

  // Get events by category
  static Future<List<ExploreEvent>> getEventsByCategory(String category) async {
    final allEvents = await fetchEventsFromAPI();
    final filteredEvents = allEvents.where((event) => 
      event['category']?.toLowerCase() == category.toLowerCase()).toList();
    
    return filteredEvents.map((eventData) => ExploreEvent.fromJson(eventData)).toList();
  }

  // Search events
  static Future<List<ExploreEvent>> searchEvents(String query) async {
    final allEvents = await fetchEventsFromAPI();
    final searchResults = allEvents.where((event) =>
      event['name']?.toLowerCase().contains(query.toLowerCase()) == true ||
      event['location']?.toLowerCase().contains(query.toLowerCase()) == true ||
      event['category']?.toLowerCase().contains(query.toLowerCase()) == true).toList();
    
    return searchResults.map((eventData) => ExploreEvent.fromJson(eventData)).toList();
  }

  // Get trending events
  static Future<List<ExploreEvent>> getTrendingEvents() async {
    final allEvents = await fetchEventsFromAPI();
    final trendingEvents = allEvents.where((event) => 
      event['badge'] == 'Trending' || event['badge'] == 'Hot' || event['badge'] == 'Popular').toList();
    
    return trendingEvents.map((eventData) => ExploreEvent.fromJson(eventData)).toList();
  }

  // Get featured events
  static Future<List<ExploreEvent>> getFeaturedEvents() async {
    final allEvents = await fetchEventsFromAPI();
    final featuredEvents = allEvents.where((event) => 
      event['badge'] == 'Featured' || event['isVerified'] == true).toList();
    
    return featuredEvents.map((eventData) => ExploreEvent.fromJson(eventData)).toList();
  }

  // Reset pagination
  static void resetPagination() {
    _currentPage = 0;
  }

  // Clear cache
  static void clearCache() {
    _cachedEvents.clear();
    _lastFetchTime = null;
  }

  // Get event categories
  static Future<List<String>> getCategories() async {
    final allEvents = await fetchEventsFromAPI();
    final categories = allEvents
        .map((event) => event['category'] as String?)
        .where((category) => category != null)
        .cast<String>()
        .toSet()
        .toList();
    
    return categories;
  }

  // Get random events
  static Future<List<ExploreEvent>> getRandomEvents(int count) async {
    final allEvents = await fetchEventsFromAPI();
    final shuffledEvents = List<Map<String, dynamic>>.from(allEvents);
    shuffledEvents.shuffle(_random);
    
    final randomEvents = shuffledEvents.take(count).toList();
    return randomEvents.map((eventData) => ExploreEvent.fromJson(eventData)).toList();
  }
}
