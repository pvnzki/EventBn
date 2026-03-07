import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:event_booking_app/features/events/services/event_service.dart';
import 'package:event_booking_app/features/events/models/event_model.dart';
import 'package:event_booking_app/features/auth/services/auth_service.dart';
import 'dart:convert';

// Mock classes
class MockClient extends Mock implements http.Client {}
class MockAuthService extends Mock implements AuthService {}

// Register fallback values for Uri
class FakeUri extends Fake implements Uri {}

void main() {
  late EventService eventService;
  late MockClient mockClient;
  late MockAuthService mockAuthService;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  setUp(() {
    mockClient = MockClient();
    mockAuthService = MockAuthService();
    eventService = EventService(
      client: mockClient,
      baseUrl: 'http://test-api',
      authService: mockAuthService,
    );

    // Setup default auth token
    when(() => mockAuthService.getStoredToken()).thenAnswer((_) async => 'test-token');
  });

  tearDown(() {
    reset(mockClient);
    reset(mockAuthService);
  });

  group('EventService.getAllEvents', () {
    test('returns list of events on successful API call', () async {
      // Arrange
      final mockResponse = {
        'success': true,
        'data': [
          {
            'event_id': 1,
            'title': 'Tech Conference 2025',
            'description': 'Annual tech conference',
            'cover_image_url': 'https://example.com/img1.jpg',
            'video_url': '',
            'category': 'Technology',
            'venue': 'Convention Center',
            'location': 'Colombo',
            'start_time': '2025-12-01T10:00:00Z',
            'end_time': '2025-12-01T18:00:00Z',
            'capacity': 500,
            'status': 'published',
            'created_at': '2025-01-01T00:00:00Z',
            'updated_at': '2025-01-01T00:00:00Z',
            'organization': {'organization_id': 1, 'name': 'Tech Org'},
          },
          {
            'event_id': 2,
            'title': 'Music Festival',
            'description': 'Summer music event',
            'cover_image_url': 'https://example.com/img2.jpg',
            'video_url': '',
            'category': 'Music',
            'venue': 'Central Park',
            'location': 'Kandy',
            'start_time': '2025-07-20T18:00:00Z',
            'end_time': '2025-07-20T23:00:00Z',
            'capacity': 1000,
            'status': 'published',
            'created_at': '2025-02-01T00:00:00Z',
            'updated_at': '2025-02-01T00:00:00Z',
            'organization': {'organization_id': 2, 'name': 'Music Corp'},
          }
        ]
      };

      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode(mockResponse),
            200,
            headers: {'content-type': 'application/json'},
          ));

      // Act
      final events = await eventService.getAllEvents();

      // Assert
      expect(events.length, 2);
      expect(events[0].id, '1');
      expect(events[0].title, 'Tech Conference 2025');
      expect(events[1].id, '2');
      expect(events[1].title, 'Music Festival');
      
      verify(() => mockClient.get(
            Uri.parse('http://test-api/api/events'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer test-token',
            },
          )).called(1);
    });

    test('throws exception on API error', () async {
      // Arrange
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({'success': false, 'message': 'Server error'}),
            500,
          ));

      // Act & Assert
      expect(
        () => eventService.getAllEvents(),
        throwsException,
      );
    });

    test('throws exception on network error', () async {
      // Arrange
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => eventService.getAllEvents(),
        throwsException,
      );
    });
  });

  group('EventService.getEventById', () {
    test('returns event on successful API call', () async {
      // Arrange
      final mockResponse = {
        'success': true,
        'data': {
          'event_id': 123,
          'title': 'Specific Event',
          'description': 'Event details',
          'cover_image_url': 'https://example.com/img.jpg',
          'video_url': '',
          'category': 'Sports',
          'venue': 'Stadium',
          'location': 'Galle',
          'start_time': '2025-08-15T14:00:00Z',
          'end_time': '2025-08-15T18:00:00Z',
          'capacity': 2000,
          'status': 'published',
          'created_at': '2025-03-01T00:00:00Z',
          'updated_at': '2025-03-01T00:00:00Z',
          'organization': {'organization_id': 5, 'name': 'Sports Inc'},
        }
      };

      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode(mockResponse),
            200,
          ));

      // Act
      final event = await eventService.getEventById('123');

      // Assert
      expect(event.id, '123');
      expect(event.title, 'Specific Event');
      expect(event.category, 'Sports');
      expect(event.venue, 'Stadium');
      
      verify(() => mockClient.get(
            Uri.parse('http://test-api/api/events/123'),
            headers: any(named: 'headers'),
          )).called(1);
    });

    test('throws exception when event not found', () async {
      // Arrange
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({'success': false, 'message': 'Event not found'}),
            404,
          ));

      // Act & Assert
      expect(
        () => eventService.getEventById('999'),
        throwsException,
      );
    });
  });

  group('EventService.searchEvents', () {
    test('returns search results on successful API call', () async {
      // Arrange
      final mockResponse = {
        'success': true,
        'data': [
          {
            'event_id': 10,
            'title': 'Tech Meetup',
            'description': 'Developer meetup',
            'cover_image_url': 'https://example.com/meetup.jpg',
            'video_url': '',
            'category': 'Technology',
            'venue': 'Coworking Space',
            'location': 'Colombo',
            'start_time': '2025-05-10T18:00:00Z',
            'end_time': '2025-05-10T20:00:00Z',
            'capacity': 50,
            'status': 'published',
            'created_at': '2025-04-01T00:00:00Z',
            'updated_at': '2025-04-01T00:00:00Z',
            'organization': {'organization_id': 3, 'name': 'Dev Community'},
          }
        ]
      };

      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode(mockResponse),
            200,
          ));

      // Act
      final events = await eventService.searchEvents('tech');

      // Assert
      expect(events.length, 1);
      expect(events[0].title, 'Tech Meetup');
      
      verify(() => mockClient.get(
            Uri.parse('http://test-api/api/events/search/tech'),
            headers: any(named: 'headers'),
          )).called(1);
    });

    test('returns empty list when no results found', () async {
      // Arrange
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({'success': true, 'data': []}),
            200,
          ));

      // Act
      final events = await eventService.searchEvents('nonexistent');

      // Assert
      expect(events, isEmpty);
    });

    test('throws exception on search error', () async {
      // Arrange
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode({'success': false, 'message': 'Search failed'}),
            500,
          ));

      // Act & Assert
      expect(
        () => eventService.searchEvents('query'),
        throwsException,
      );
    });
  });

  group('EventService.getEventAttendees', () {
    test('returns list of attendees on successful API call', () async {
      // Arrange
      final mockResponse = {
        'success': true,
        'data': [
          {'id': '1', 'username': 'Alice', 'avatar': 'https://example.com/alice.jpg'},
          {'id': '2', 'username': 'Bob', 'avatar': 'https://example.com/bob.jpg'},
        ]
      };

      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            jsonEncode(mockResponse),
            200,
          ));

      // Act
      final attendees = await eventService.getEventAttendees('123');

      // Assert
      expect(attendees.length, 2);
      expect(attendees[0]['username'], 'Alice');
      expect(attendees[1]['username'], 'Bob');
    });

    test('throws exception when fetch fails', () async {
      // Arrange
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(
            'Not Found',
            404,
          ));

      // Act & Assert
      expect(
        () => eventService.getEventAttendees('999'),
        throwsException,
      );
    });
  });
}
