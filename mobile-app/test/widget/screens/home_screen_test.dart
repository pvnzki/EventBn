import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:event_booking_app/features/events/screens/home_screen.dart';
import 'package:event_booking_app/features/events/providers/event_provider.dart';
import 'package:event_booking_app/features/events/models/event_model.dart';

// Mock EventProvider
class MockEventProvider extends Mock implements EventProvider {}

void main() {
  late MockEventProvider mockEventProvider;

  setUp(() {
    mockEventProvider = MockEventProvider();
    
    // Setup default behaviors
    when(() => mockEventProvider.events).thenReturn([]);
    when(() => mockEventProvider.featuredEvents).thenReturn([]);
    when(() => mockEventProvider.currentEvent).thenReturn(null);
    when(() => mockEventProvider.isLoading).thenReturn(false);
    when(() => mockEventProvider.error).thenReturn(null);
    when(() => mockEventProvider.fetchEvents()).thenAnswer((_) async {});
    when(() => mockEventProvider.searchEvents(any())).thenAnswer((_) async => []);
    when(() => mockEventProvider.clearError()).thenReturn(null);
  });

  Widget wrapWithProviders(Widget child) {
    return MaterialApp(
      home: ChangeNotifierProvider<EventProvider>.value(
        value: mockEventProvider,
        child: child,
      ),
    );
  }

  // TODO: Re-enable these tests after refactoring HomeScreen
  // Currently, HomeScreen has several issues that make it difficult to test:
  // 1. Directly instantiates AuthService in _fetchEventPricing (line ~1267)
  // 2. Uses AppConfig.baseUrl which requires .env
  // 3. Creates its own state management for search, filters, etc.
  // 4. Makes direct HTTP calls in the widget for pricing
  
  group('HomeScreen - Component Tests', () {
    test('HomeScreen requires refactoring for comprehensive testing', () {
      // HomeScreen currently has tight coupling with:
      // - AuthService (line 1267): final authService = AuthService();
      // - AppConfig.baseUrl (line 1274): '${AppConfig.baseUrl}/api/events/...'
      // - Direct HTTP calls (line 1275): await http.get(...)
      // - Complex internal state (_searchResults, _eventPriceCache, etc.)
      //
      // To enable proper testing, HomeScreen should:
      // 1. Accept EventService via Provider or constructor
      // 2. Move pricing logic to EventService or separate service
      // 3. Inject AuthService rather than creating it
      // 4. Use EventProvider for all event-related state
      
      expect(true, true); // Placeholder
    });
  });

  group('HomeScreen - Loading State Tests', () {
    testWidgets('should show loading indicator when events are loading', (tester) async {
      // Arrange
      when(() => mockEventProvider.isLoading).thenReturn(true);
      when(() => mockEventProvider.events).thenReturn([]);
      when(() => mockEventProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(wrapWithProviders(const HomeScreen()));
      await tester.pump(); // Process the first frame

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('HomeScreen - Error State Tests', () {
    testWidgets('should show error message when events fail to load', (tester) async {
      // Arrange
      when(() => mockEventProvider.isLoading).thenReturn(false);
      when(() => mockEventProvider.events).thenReturn([]);
      when(() => mockEventProvider.error).thenReturn('Failed to fetch events');

      // Act
      await tester.pumpWidget(wrapWithProviders(const HomeScreen()));
      await tester.pump(); // Use pump() instead of pumpAndSettle() due to continuous banner animation

      // Assert
      expect(find.text('Unable to connect to server.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should call fetchEvents when retry button is tapped', (tester) async {
      // Arrange
      when(() => mockEventProvider.isLoading).thenReturn(false);
      when(() => mockEventProvider.events).thenReturn([]);
      when(() => mockEventProvider.error).thenReturn('Failed to fetch events');

      // Act
      await tester.pumpWidget(wrapWithProviders(const HomeScreen()));
      await tester.pump(); // Use pump() instead of pumpAndSettle() due to continuous banner animation

      // Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pump(); // Use pump() instead of pumpAndSettle() due to continuous banner animation

      // Assert
      verify(() => mockEventProvider.fetchEvents()).called(greaterThan(0));
    });
  });

  group('HomeScreen - Empty State Tests', () {
    testWidgets('should show empty state when no events are available', (tester) async {
      // Arrange
      when(() => mockEventProvider.isLoading).thenReturn(false);
      when(() => mockEventProvider.events).thenReturn([]);
      when(() => mockEventProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(wrapWithProviders(const HomeScreen()));
      await tester.pump(); // Use pump() instead of pumpAndSettle() due to continuous banner animation

      // Assert
      expect(find.text('No events found'), findsOneWidget);
    });
  });

  group('HomeScreen - Events Display Tests', () {
    testWidgets('should display events in grid when events are available', (tester) async {
      // Arrange
      final mockEvents = [
        Event(
          id: '1',
          title: 'Tech Conference 2025',
          description: 'Annual tech event',
          imageUrl: 'https://example.com/img1.jpg',
          otherImagesUrl: '',
          videoUrl: '',
          category: 'Technology',
          venue: 'Convention Center',
          address: 'Colombo',
          startDateTime: DateTime.parse('2025-12-01T10:00:00Z'),
          endDateTime: DateTime.parse('2025-12-01T18:00:00Z'),
          ticketTypes: const [],
          organizationId: '1',
          organizerName: 'Tech Org',
          totalCapacity: 500,
          soldTickets: 0,
          isActive: true,
          createdAt: DateTime.parse('2025-01-01T00:00:00Z'),
          updatedAt: DateTime.parse('2025-01-01T00:00:00Z'),
        ),
        Event(
          id: '2',
          title: 'Music Festival',
          description: 'Summer music event',
          imageUrl: 'https://example.com/img2.jpg',
          otherImagesUrl: '',
          videoUrl: '',
          category: 'Music',
          venue: 'Central Park',
          address: 'Kandy',
          startDateTime: DateTime.parse('2025-07-20T18:00:00Z'),
          endDateTime: DateTime.parse('2025-07-20T23:00:00Z'),
          ticketTypes: const [],
          organizationId: '2',
          organizerName: 'Music Corp',
          totalCapacity: 1000,
          soldTickets: 0,
          isActive: true,
          createdAt: DateTime.parse('2025-02-01T00:00:00Z'),
          updatedAt: DateTime.parse('2025-02-01T00:00:00Z'),
        ),
      ];

      when(() => mockEventProvider.isLoading).thenReturn(false);
      when(() => mockEventProvider.events).thenReturn(mockEvents);
      when(() => mockEventProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(wrapWithProviders(const HomeScreen()));
      await tester.pump(); // Use pump() instead of pumpAndSettle() due to continuous banner animation

      // Assert
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Tech Conference 2025'), findsOneWidget);
      expect(find.text('Music Festival'), findsOneWidget);
    });
  });

  group('HomeScreen - Category Filter Tests', () {
    testWidgets('should display category chips', (tester) async {
      // Arrange
      when(() => mockEventProvider.isLoading).thenReturn(false);
      when(() => mockEventProvider.events).thenReturn([]);
      when(() => mockEventProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(wrapWithProviders(const HomeScreen()));
      await tester.pump(); // Use pump() instead of pumpAndSettle() due to continuous banner animation

      // Assert - Check if category section exists
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Concerts'), findsOneWidget);
      expect(find.text('Sports'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Art'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
    });
  });

  group('HomeScreen - Search Bar Tests', () {
    testWidgets('should display search bar', (tester) async {
      // Arrange
      when(() => mockEventProvider.isLoading).thenReturn(false);
      when(() => mockEventProvider.events).thenReturn([]);
      when(() => mockEventProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(wrapWithProviders(const HomeScreen()));
      await tester.pump(); // Use pump() instead of pumpAndSettle() due to continuous banner animation

      // Assert
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search for events'), findsOneWidget);
    });
  });

  group('HomeScreen - Banner Tests', () {
    testWidgets('should display promotional banner', (tester) async {
      // Arrange
      when(() => mockEventProvider.isLoading).thenReturn(false);
      when(() => mockEventProvider.events).thenReturn([]);
      when(() => mockEventProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(wrapWithProviders(const HomeScreen()));
      await tester.pump(); // Use pump() instead of pumpAndSettle() due to continuous banner animation

      // Assert - PageView should exist for banner
      expect(find.byType(PageView), findsOneWidget);
    });
  });

  group('HomeScreen - Header Tests', () {
    testWidgets('should display header with notification icon', (tester) async {
      // Arrange
      when(() => mockEventProvider.isLoading).thenReturn(false);
      when(() => mockEventProvider.events).thenReturn([]);
      when(() => mockEventProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(wrapWithProviders(const HomeScreen()));
      await tester.pump(); // Use pump() instead of pumpAndSettle() due to continuous banner animation

      // Assert
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });
  });
}
