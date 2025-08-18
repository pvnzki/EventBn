import 'dart:math';
import '../models/event_model.dart';

class ExploreDataService {
  static final _random = Random();
  static int _currentPage = 0;
  static const int _pageSize = 10;

  // Mock event data
  static final List<Map<String, dynamic>> _allEvents = [
    {
      'id': '1',
      'name': 'Summer Music Festival 2025',
      'imageUrl':
          'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800',
      'location': 'Central Park, NYC',
      'date': '2025-07-15T18:00:00Z',
      'category': 'Music',
      'price': 89.99,
      'badge': 'Trending',
      'attendees': 2500,
      'isVerified': true,
      'rating': 4.8,
    },
    {
      'id': '2',
      'name': 'Tech Innovation Summit',
      'imageUrl':
          'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
      'location': 'Silicon Valley, CA',
      'date': '2025-08-20T09:00:00Z',
      'category': 'Tech',
      'price': 299.99,
      'badge': 'Featured',
      'attendees': 1200,
      'isVerified': true,
      'rating': 4.9,
    },
    {
      'id': '3',
      'name': 'Street Food Carnival',
      'imageUrl':
          'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
      'location': 'Downtown LA',
      'date': '2025-06-10T12:00:00Z',
      'category': 'Food',
      'price': 25.00,
      'badge': 'New',
      'attendees': 800,
      'isVerified': false,
      'rating': 4.5,
    },
    {
      'id': '4',
      'name': 'Basketball Championship Finals',
      'imageUrl':
          'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800',
      'location': 'Madison Square Garden',
      'date': '2025-09-05T19:30:00Z',
      'category': 'Sports',
      'price': 150.00,
      'badge': 'Hot',
      'attendees': 20000,
      'isVerified': true,
      'rating': 4.7,
    },
    {
      'id': '5',
      'name': 'Contemporary Art Exhibition',
      'imageUrl':
          'https://images.unsplash.com/photo-1578321272176-b7bbc0679853?w=800',
      'location': 'MoMA, NYC',
      'date': '2025-07-01T10:00:00Z',
      'category': 'Art',
      'price': 45.00,
      'attendees': 500,
      'isVerified': true,
      'rating': 4.6,
    },
    {
      'id': '6',
      'name': 'Startup Pitch Competition',
      'imageUrl':
          'https://images.unsplash.com/photo-1559136555-9303baea8ebd?w=800',
      'location': 'Boston Convention Center',
      'date': '2025-08-12T14:00:00Z',
      'category': 'Business',
      'price': 75.00,
      'badge': 'Featured',
      'attendees': 600,
      'isVerified': true,
      'rating': 4.4,
    },
    {
      'id': '7',
      'name': 'Jazz Night Under the Stars',
      'imageUrl':
          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800',
      'location': 'Rooftop Lounge, Miami',
      'date': '2025-06-25T20:00:00Z',
      'category': 'Music',
      'price': 65.00,
      'attendees': 200,
      'isVerified': false,
      'rating': 4.8,
    },
    {
      'id': '8',
      'name': 'Coding Bootcamp Workshop',
      'imageUrl':
          'https://images.unsplash.com/photo-1517180102446-f3ece451e9d8?w=800',
      'location': 'Tech Hub, Seattle',
      'date': '2025-07-08T09:00:00Z',
      'category': 'Education',
      'price': 120.00,
      'badge': 'New',
      'attendees': 150,
      'isVerified': true,
      'rating': 4.3,
    },
    {
      'id': '9',
      'name': 'Wine Tasting Evening',
      'imageUrl':
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
      'location': 'Napa Valley, CA',
      'date': '2025-09-15T18:30:00Z',
      'category': 'Food',
      'price': 85.00,
      'attendees': 100,
      'isVerified': true,
      'rating': 4.9,
    },
    {
      'id': '10',
      'name': 'Electronic Dance Festival',
      'imageUrl':
          'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800',
      'location': 'Las Vegas Strip',
      'date': '2025-10-01T22:00:00Z',
      'category': 'Music',
      'price': 199.99,
      'badge': 'Trending',
      'attendees': 5000,
      'isVerified': true,
      'rating': 4.7,
    },
    // Add more events for pagination
    {
      'id': '11',
      'name': 'Marathon Championship',
      'imageUrl':
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
      'location': 'Chicago, IL',
      'date': '2025-06-30T06:00:00Z',
      'category': 'Sports',
      'price': 50.00,
      'attendees': 15000,
      'isVerified': true,
      'rating': 4.5,
    },
    {
      'id': '12',
      'name': 'Digital Marketing Workshop',
      'imageUrl':
          'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800',
      'location': 'Austin, TX',
      'date': '2025-08-05T13:00:00Z',
      'category': 'Business',
      'price': 95.00,
      'badge': 'Hot',
      'attendees': 300,
      'isVerified': false,
      'rating': 4.2,
    },
  ];

  static Future<List<ExploreEvent>> loadEvents({
    int page = 0,
    ExploreEventCategory category = ExploreEventCategory.all,
    String? searchQuery,
  }) async {
    // Simulate API delay
    await Future.delayed(Duration(milliseconds: _random.nextInt(1000) + 500));

    var filteredEvents = _allEvents.where((event) {
      bool matchesCategory = category == ExploreEventCategory.all ||
          event['category'].toString().toLowerCase() ==
              category.label.toLowerCase();

      bool matchesSearch = searchQuery == null ||
          searchQuery.isEmpty ||
          event['name']
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          event['location']
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();

    // Shuffle for variety (simulate random API results)
    if (page == 0) {
      filteredEvents.shuffle(_random);
    }

    int startIndex = page * _pageSize;
    int endIndex = (startIndex + _pageSize).clamp(0, filteredEvents.length);

    if (startIndex >= filteredEvents.length) {
      return [];
    }

    var pageEvents = filteredEvents.sublist(startIndex, endIndex);
    return pageEvents.map((json) => ExploreEvent.fromJson(json)).toList();
  }

  static Future<List<ExploreEvent>> refreshEvents({
    ExploreEventCategory category = ExploreEventCategory.all,
    String? searchQuery,
  }) async {
    _currentPage = 0;
    return loadEvents(
        page: _currentPage, category: category, searchQuery: searchQuery);
  }

  static Future<List<ExploreEvent>> loadMoreEvents({
    ExploreEventCategory category = ExploreEventCategory.all,
    String? searchQuery,
  }) async {
    _currentPage++;
    return loadEvents(
        page: _currentPage, category: category, searchQuery: searchQuery);
  }

  static void resetPagination() {
    _currentPage = 0;
  }
}
