import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:event_booking_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('EventBn App Integration Tests', () {
    testWidgets('Complete user flow - Browse to Book', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify home screen is displayed
      expect(find.text('Events'), findsOneWidget);

      // Tap on an event
      final eventCard = find.byType(Card).first;
      await tester.tap(eventCard);
      await tester.pumpAndSettle();

      // Verify event details screen
      expect(find.text('Book Now'), findsOneWidget);

      // Test would continue with booking flow...
    });

    testWidgets('Ticket cancellation flow', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to tickets screen
      final ticketsNavButton = find.byIcon(Icons.confirmation_number);
      await tester.tap(ticketsNavButton);
      await tester.pumpAndSettle();

      // Verify tickets screen
      expect(find.text('Upcoming'), findsOneWidget);

      // If there are cancellable tickets, test cancellation
      final cancelButton = find.text('Cancel Booking');
      if (cancelButton.evaluate().isNotEmpty) {
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();

        // Confirm cancellation
        final confirmButton = find.text('Yes, Cancel');
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();

        // Verify cancellation success
        expect(find.text('Tickets cancelled successfully'), findsOneWidget);
      }
    });

    testWidgets('Authentication flow', (tester) async {
      // Test login/logout flow
      app.main();
      await tester.pumpAndSettle();

      // Navigate to profile
      final profileButton = find.byIcon(Icons.person);
      await tester.tap(profileButton);
      await tester.pumpAndSettle();

      // Verify profile screen
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Search functionality', (tester) async {
      // Test event search
      app.main();
      await tester.pumpAndSettle();

      // Tap search icon
      final searchIcon = find.byIcon(Icons.search);
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Concert');
      await tester.pumpAndSettle();

      // Verify search results
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('Navigation between screens', (tester) async {
      // Test bottom navigation
      app.main();
      await tester.pumpAndSettle();

      // Test each tab
      final tabs = [
        Icons.home,
        Icons.confirmation_number,
        Icons.person,
      ];

      for (final icon in tabs) {
        await tester.tap(find.byIcon(icon));
        await tester.pumpAndSettle();
        
        // Verify screen changed
        expect(find.byIcon(icon), findsOneWidget);
      }
    });

    testWidgets('Pull to refresh', (tester) async {
      // Test refresh on various screens
      app.main();
      await tester.pumpAndSettle();

      // Navigate to tickets
      await tester.tap(find.byIcon(Icons.confirmation_number));
      await tester.pumpAndSettle();

      // Pull to refresh
      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      // Verify loading indicator appeared
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Error handling and retry', (tester) async {
      // Test error states and retry functionality
      app.main();
      await tester.pumpAndSettle();

      // Navigate to tickets
      await tester.tap(find.byIcon(Icons.confirmation_number));
      await tester.pumpAndSettle();

      // If there's a retry button, test it
      final retryButton = find.text('Retry');
      if (retryButton.evaluate().isNotEmpty) {
        await tester.tap(retryButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Performance - Screen transitions', (tester) async {
      // Test that transitions are smooth
      app.main();
      await tester.pumpAndSettle();

      // Navigate through screens and measure timing
      final stopwatch = Stopwatch()..start();
      
      await tester.tap(find.byIcon(Icons.confirmation_number));
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      
      // Verify transition was fast enough (< 1 second)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });

  group('Network Connectivity Tests', () {
    testWidgets('Handle offline scenario', (tester) async {
      // Test behavior when offline
      app.main();
      await tester.pumpAndSettle();

      // Navigate to tickets
      await tester.tap(find.byIcon(Icons.confirmation_number));
      await tester.pumpAndSettle();

      // Would need to simulate network disconnection
      // Then verify appropriate error message is shown
    });

    testWidgets('Handle slow network', (tester) async {
      // Test loading states with slow network
    });
  });

  group('Data Persistence Tests', () {
    testWidgets('Cached data loads on app start', (tester) async {
      // Test that cached data is displayed before API response
      app.main();
      await tester.pumpAndSettle();

      // Verify cached events are shown
    });

    testWidgets('Token persists across sessions', (tester) async {
      // Test authentication token persistence
    });
  });
}

/*
To run these integration tests:

1. Connect a device or start an emulator

2. Run from command line:
   flutter test integration_test/app_test.dart

3. Or run all integration tests:
   flutter test integration_test/

Note: Integration tests run on actual devices/emulators,
so they take longer than unit tests.
*/
