import 'package:flutter_test/flutter_test.dart';
import 'package:event_booking_app/features/tickets/models/ticket_model.dart';

void main() {
  group('Ticket Model', () {
    late Ticket testTicket;

    setUp(() {
      testTicket = Ticket(
        id: 'ticket-123',
        eventId: 'event-1',
        eventTitle: 'Test Event',
        eventImageUrl: 'https://example.com/image.jpg',
        userId: 'user-1',
        ticketTypeId: 'type-1',
        ticketTypeName: 'General Admission',
        price: 5000.0,
        quantity: 1,
        totalAmount: 5000.0,
        qrCode: 'QR123',
        status: TicketStatus.active,
        purchaseDate: DateTime(2025, 10, 20),
        eventStartDate: DateTime(2025, 10, 30),
        venue: 'Test Venue',
        address: 'Test Address',
        paymentId: 'payment-123',
      );
    });

    test('should create a valid Ticket instance', () {
      expect(testTicket.id, 'ticket-123');
      expect(testTicket.eventTitle, 'Test Event');
      expect(testTicket.price, 5000.0);
      expect(testTicket.status, TicketStatus.active);
    });

    test('isUpcoming should return true for future events', () {
      final upcomingTicket = Ticket(
        id: 'ticket-123',
        eventId: 'event-1',
        eventTitle: 'Test Event',
        eventImageUrl: 'https://example.com/image.jpg',
        userId: 'user-1',
        ticketTypeId: 'type-1',
        ticketTypeName: 'General Admission',
        price: 5000.0,
        quantity: 1,
        totalAmount: 5000.0,
        qrCode: 'QR123',
        status: TicketStatus.active,
        purchaseDate: DateTime.now(),
        eventStartDate: DateTime.now().add(const Duration(days: 7)),
        venue: 'Test Venue',
        address: 'Test Address',
        paymentId: 'payment-123',
      );

      expect(upcomingTicket.isUpcoming, true);
    });

    test('isPast should return true for past events', () {
      final pastTicket = Ticket(
        id: 'ticket-123',
        eventId: 'event-1',
        eventTitle: 'Test Event',
        eventImageUrl: 'https://example.com/image.jpg',
        userId: 'user-1',
        ticketTypeId: 'type-1',
        ticketTypeName: 'General Admission',
        price: 5000.0,
        quantity: 1,
        totalAmount: 5000.0,
        qrCode: 'QR123',
        status: TicketStatus.active,
        purchaseDate: DateTime.now(),
        eventStartDate: DateTime.now().subtract(const Duration(days: 7)),
        venue: 'Test Venue',
        address: 'Test Address',
        paymentId: 'payment-123',
      );

      expect(pastTicket.isPast, true);
    });

    test('isActive should return correct status', () {
      expect(testTicket.isActive, true);

      final cancelledTicket = Ticket(
        id: 'ticket-123',
        eventId: 'event-1',
        eventTitle: 'Test Event',
        eventImageUrl: 'https://example.com/image.jpg',
        userId: 'user-1',
        ticketTypeId: 'type-1',
        ticketTypeName: 'General Admission',
        price: 5000.0,
        quantity: 1,
        totalAmount: 5000.0,
        qrCode: 'QR123',
        status: TicketStatus.cancelled,
        purchaseDate: DateTime.now(),
        eventStartDate: DateTime.now().add(const Duration(days: 7)),
        venue: 'Test Venue',
        address: 'Test Address',
        paymentId: 'payment-123',
      );

      expect(cancelledTicket.isActive, false);
      expect(cancelledTicket.isCancelled, true);
    });

    test('toJson should serialize correctly', () {
      final json = testTicket.toJson();

      expect(json['id'], 'ticket-123');
      expect(json['eventTitle'], 'Test Event');
      expect(json['price'], 5000.0);
      expect(json['status'], 'active');
    });

    test('fromJson should deserialize correctly', () {
      final json = {
        'id': 'ticket-456',
        'eventId': 'event-2',
        'eventTitle': 'Another Event',
        'eventImageUrl': 'https://example.com/image2.jpg',
        'userId': 'user-2',
        'ticketTypeId': 'type-2',
        'ticketTypeName': 'VIP',
        'price': 10000.0,
        'quantity': 2,
        'totalAmount': 20000.0,
        'qrCode': 'QR456',
        'status': 'active',
        'purchaseDate': DateTime(2025, 10, 21).toIso8601String(),
        'eventStartDate': DateTime(2025, 11, 1).toIso8601String(),
        'venue': 'Another Venue',
        'address': 'Another Address',
        'paymentId': 'payment-456',
      };

      final ticket = Ticket.fromJson(json);

      expect(ticket.id, 'ticket-456');
      expect(ticket.eventTitle, 'Another Event');
      expect(ticket.price, 10000.0);
      expect(ticket.quantity, 2);
    });
  });

  group('PaymentGroup Model', () {
    late PaymentGroup testGroup;

    setUp(() {
      final tickets = [
        Ticket(
          id: 'ticket-1',
          eventId: 'event-1',
          eventTitle: 'Test Event',
          eventImageUrl: 'https://example.com/image.jpg',
          userId: 'user-1',
          ticketTypeId: 'type-1',
          ticketTypeName: 'General',
          price: 5000.0,
          quantity: 1,
          totalAmount: 5000.0,
          qrCode: 'QR1',
          status: TicketStatus.active,
          purchaseDate: DateTime.now(),
          eventStartDate: DateTime.now().add(const Duration(hours: 3)),
          venue: 'Venue',
          address: 'Address',
          paymentId: 'payment-123',
        ),
      ];

      testGroup = PaymentGroup(
        paymentId: 'payment-123',
        tickets: tickets,
        totalAmount: 5000.0,
        purchaseDate: DateTime.now(),
        paymentMethod: 'Card',
        paymentStatus: 'completed',
        eventTitle: 'Test Event',
        eventStartTime: DateTime.now().add(const Duration(hours: 3)),
        eventVenue: 'Test Venue',
        eventLocation: 'Test Location',
        coverImageUrl: 'https://example.com/image.jpg',
        ticketCount: 1,
        canCancel: true,
        hoursUntilEvent: 3.0,
      );
    });

    test('should create a valid PaymentGroup instance', () {
      expect(testGroup.paymentId, 'payment-123');
      expect(testGroup.tickets.length, 1);
      expect(testGroup.totalAmount, 5000.0);
      expect(testGroup.canCancel, true);
    });

    test('canBeCancelled should use backend canCancel flag', () {
      expect(testGroup.canBeCancelled, true);

      final nonCancellableGroup = PaymentGroup(
        paymentId: 'payment-456',
        tickets: testGroup.tickets,
        totalAmount: 5000.0,
        purchaseDate: DateTime.now(),
        paymentMethod: 'Card',
        paymentStatus: 'completed',
        eventTitle: 'Test Event',
        eventStartTime: DateTime.now().add(const Duration(minutes: 30)),
        eventVenue: 'Test Venue',
        eventLocation: 'Test Location',
        coverImageUrl: 'https://example.com/image.jpg',
        ticketCount: 1,
        canCancel: false,
        hoursUntilEvent: 0.5,
      );

      expect(nonCancellableGroup.canBeCancelled, false);
    });

    test('isFullyCancelled should check all tickets', () {
      expect(testGroup.isFullyCancelled, false);

      final cancelledTickets = [
        Ticket(
          id: 'ticket-1',
          eventId: 'event-1',
          eventTitle: 'Test Event',
          eventImageUrl: 'https://example.com/image.jpg',
          userId: 'user-1',
          ticketTypeId: 'type-1',
          ticketTypeName: 'General',
          price: 5000.0,
          quantity: 1,
          totalAmount: 5000.0,
          qrCode: 'QR1',
          status: TicketStatus.cancelled,
          purchaseDate: DateTime.now(),
          eventStartDate: DateTime.now().add(const Duration(days: 1)),
          venue: 'Venue',
          address: 'Address',
          paymentId: 'payment-123',
        ),
      ];

      final cancelledGroup = PaymentGroup(
        paymentId: 'payment-123',
        tickets: cancelledTickets,
        totalAmount: 5000.0,
        purchaseDate: DateTime.now(),
        paymentMethod: 'Card',
        paymentStatus: 'refunded',
        eventTitle: 'Test Event',
        canCancel: false,
        ticketCount: 1,
      );

      expect(cancelledGroup.isFullyCancelled, true);
    });

    test('hasUsedTickets should check ticket status', () {
      expect(testGroup.hasUsedTickets, false);

      final usedTickets = [
        Ticket(
          id: 'ticket-1',
          eventId: 'event-1',
          eventTitle: 'Test Event',
          eventImageUrl: 'https://example.com/image.jpg',
          userId: 'user-1',
          ticketTypeId: 'type-1',
          ticketTypeName: 'General',
          price: 5000.0,
          quantity: 1,
          totalAmount: 5000.0,
          qrCode: 'QR1',
          status: TicketStatus.used,
          purchaseDate: DateTime.now(),
          eventStartDate: DateTime.now().subtract(const Duration(days: 1)),
          venue: 'Venue',
          address: 'Address',
          paymentId: 'payment-123',
        ),
      ];

      final groupWithUsedTickets = PaymentGroup(
        paymentId: 'payment-123',
        tickets: usedTickets,
        totalAmount: 5000.0,
        purchaseDate: DateTime.now(),
        paymentMethod: 'Card',
        paymentStatus: 'completed',
        eventTitle: 'Test Event',
        canCancel: false,
        ticketCount: 1,
      );

      expect(groupWithUsedTickets.hasUsedTickets, true);
    });
  });
}
