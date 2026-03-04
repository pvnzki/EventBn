import 'package:flutter_test/flutter_test.dart';
import 'package:event_booking_app/features/events/models/event_model.dart';

void main() {
  group('Event Model Tests', () {
    test('Event.fromJson should parse valid JSON correctly', () {
      // Arrange
      final json = {
        'event_id': 123,
        'title': 'Tech Summit 2025',
        'description': 'Annual tech conference',
        'cover_image_url': 'https://example.com/image.jpg',
        'other_images_url': 'https://example.com/img1.jpg,https://example.com/img2.jpg',
        'video_url': 'https://example.com/video.mp4',
        'category': 'Technology',
        'venue': 'Convention Center',
        'location': '123 Main St, Colombo',
        'start_time': '2025-12-01T10:00:00Z',
        'end_time': '2025-12-01T18:00:00Z',
        'capacity': 500,
        'status': 'published',
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-15T00:00:00Z',
        'organization': {
          'organization_id': 456,
          'name': 'Tech Org'
        },
        'seat_map': '[{"ticketType":"VIP","price":5000},{"ticketType":"General","price":2000}]'
      };

      // Act
      final event = Event.fromJson(json);

      // Assert
      expect(event.id, '123');
      expect(event.title, 'Tech Summit 2025');
      expect(event.description, 'Annual tech conference');
      expect(event.imageUrl, 'https://example.com/image.jpg');
      expect(event.category, 'Technology');
      expect(event.venue, 'Convention Center');
      expect(event.address, '123 Main St, Colombo');
      expect(event.totalCapacity, 500);
      expect(event.isActive, true);
      expect(event.organizerName, 'Tech Org');
      expect(event.organizationId, '456');
      expect(event.ticketTypes.length, 2); // Should parse VIP and General
    });

    test('Event.fromJson should handle missing optional fields', () {
      // Arrange
      final json = {
        'event_id': 789,
        'title': 'Simple Event',
        'start_time': '2025-06-15T14:00:00Z',
        'end_time': '2025-06-15T16:00:00Z',
      };

      // Act
      final event = Event.fromJson(json);

      // Assert
      expect(event.id, '789');
      expect(event.title, 'Simple Event');
      expect(event.description, '');
      expect(event.imageUrl, '');
      expect(event.videoUrl, '');
      expect(event.category, '');
      expect(event.venue, '');
      expect(event.address, '');
      expect(event.totalCapacity, 0);
      expect(event.ticketTypes, isEmpty);
    });

    test('Event.toJson should serialize correctly', () {
      // Arrange
      final event = Event(
        id: '123',
        title: 'Music Festival',
        description: 'Summer music event',
        imageUrl: 'https://example.com/music.jpg',
        otherImagesUrl: '',
        videoUrl: '',
        category: 'Music',
        venue: 'Central Park',
        address: 'NYC',
        startDateTime: DateTime.parse('2025-07-20T18:00:00Z'),
        endDateTime: DateTime.parse('2025-07-20T23:00:00Z'),
        ticketTypes: const [],
        organizationId: '999',
        organizerName: 'Music Corp',
        totalCapacity: 1000,
        soldTickets: 0,
        isActive: true,
        createdAt: DateTime.parse('2025-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T00:00:00Z'),
      );

      // Act
      final json = event.toJson();

      // Assert
      expect(json['event_id'], '123'); // toJson uses event_id not id
      expect(json['title'], 'Music Festival');
      expect(json['category'], 'Music');
      expect(json['venue'], 'Central Park');
      expect(json['location'], 'NYC'); // toJson uses location not address
      expect(json['status'], 'published');
    });

    test('Event.cheapestPrice should return lowest ticket price', () {
      // Arrange
      final event = Event(
        id: '1',
        title: 'Test Event',
        description: '',
        imageUrl: '',
        otherImagesUrl: '',
        videoUrl: '',
        category: 'Test',
        venue: 'Test Venue',
        address: 'Test Address',
        startDateTime: DateTime.now(),
        endDateTime: DateTime.now(),
        ticketTypes: const [
          TicketType(id: '1', name: 'VIP', description: 'VIP Access', price: 5000, totalQuantity: 50, soldQuantity: 0, maxPerOrder: 10),
          TicketType(id: '2', name: 'General', description: 'General Admission', price: 1500, totalQuantity: 200, soldQuantity: 0, maxPerOrder: 5),
          TicketType(id: '3', name: 'Early Bird', description: 'Early Bird Special', price: 1000, totalQuantity: 100, soldQuantity: 0, maxPerOrder: 4),
        ],
        organizationId: '1',
        organizerName: 'Test Org',
        totalCapacity: 350,
        soldTickets: 0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final cheapest = event.cheapestPrice;

      // Assert
      expect(cheapest, 1000.0);
    });

    test('Event.cheapestPrice should return 0 when no ticket types', () {
      // Arrange
      final event = Event(
        id: '1',
        title: 'Free Event',
        description: '',
        imageUrl: '',
        otherImagesUrl: '',
        videoUrl: '',
        category: 'Test',
        venue: 'Test Venue',
        address: 'Test Address',
        startDateTime: DateTime.now(),
        endDateTime: DateTime.now(),
        ticketTypes: const [],
        organizationId: '1',
        organizerName: 'Test Org',
        totalCapacity: 100,
        soldTickets: 0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final cheapest = event.cheapestPrice;

      // Assert
      expect(cheapest, 0.0);
    });
  });

  group('TicketType Model Tests', () {
    test('TicketType.fromJson should parse valid JSON correctly', () {
      // Arrange
      final json = {
        'id': 'vip-001',
        'name': 'VIP',
        'description': 'VIP Access with premium features',
        'price': 5000,
        'totalQuantity': 50,
        'soldQuantity': 10,
        'maxPerOrder': 8,
      };

      // Act
      final ticketType = TicketType.fromJson(json);

      // Assert
      expect(ticketType.id, 'vip-001');
      expect(ticketType.name, 'VIP');
      expect(ticketType.description, 'VIP Access with premium features');
      expect(ticketType.price, 5000.0);
      expect(ticketType.totalQuantity, 50);
      expect(ticketType.soldQuantity, 10);
      expect(ticketType.maxPerOrder, 8);
    });

    test('TicketType.toJson should serialize correctly', () {
      // Arrange
      const ticketType = TicketType(
        id: 'general',
        name: 'General Admission',
        description: 'Standard access',
        price: 2500,
        totalQuantity: 200,
        soldQuantity: 50,
        maxPerOrder: 5,
      );

      // Act
      final json = ticketType.toJson();

      // Assert
      expect(json['id'], 'general');
      expect(json['name'], 'General Admission');
      expect(json['description'], 'Standard access');
      expect(json['price'], 2500);
      expect(json['totalQuantity'], 200);
      expect(json['soldQuantity'], 50);
      expect(json['maxPerOrder'], 5);
    });

    test('TicketType.isAvailable should return true when tickets remain', () {
      // Arrange
      const ticketType = TicketType(
        id: '1',
        name: 'General',
        description: '',
        price: 1000,
        totalQuantity: 100,
        soldQuantity: 50,
        maxPerOrder: 5,
      );

      // Act & Assert
      expect(ticketType.isAvailable, true);
      expect(ticketType.availableQuantity, 50);
    });

    test('TicketType.isAvailable should return false when sold out', () {
      // Arrange
      const ticketType = TicketType(
        id: '1',
        name: 'VIP',
        description: '',
        price: 5000,
        totalQuantity: 50,
        soldQuantity: 50,
        maxPerOrder: 10,
      );

      // Act & Assert
      expect(ticketType.isAvailable, false);
      expect(ticketType.availableQuantity, 0);
    });
  });
}
