import 'package:event_booking_app/features/tickets/models/ticket_model.dart';

/// Mock data for testing
class MockTicketData {
  static Ticket createMockTicket({
    String? id,
    String? eventTitle,
    TicketStatus? status,
    DateTime? eventStartDate,
  }) {
    return Ticket(
      id: id ?? 'ticket-123',
      eventId: 'event-1',
      eventTitle: eventTitle ?? 'Test Event',
      eventImageUrl: 'https://example.com/image.jpg',
      userId: 'user-1',
      ticketTypeId: 'type-1',
      ticketTypeName: 'General Admission',
      price: 5000.0,
      quantity: 1,
      totalAmount: 5000.0,
      qrCode: 'QR123',
      status: status ?? TicketStatus.active,
      purchaseDate: DateTime.now().subtract(const Duration(days: 1)),
      eventStartDate: eventStartDate ?? DateTime.now().add(const Duration(days: 7)),
      venue: 'Test Venue',
      address: 'Test Address',
      paymentId: 'payment-123',
    );
  }

  static List<Ticket> createMockTicketList({int count = 3}) {
    return List.generate(
      count,
      (index) => createMockTicket(
        id: 'ticket-$index',
        eventTitle: 'Test Event $index',
      ),
    );
  }

  static PaymentGroup createMockPaymentGroup({
    String? paymentId,
    bool canCancel = true,
  }) {
    final tickets = [
      createMockTicket(id: 'ticket-1'),
      createMockTicket(id: 'ticket-2'),
    ];

    return PaymentGroup(
      paymentId: paymentId ?? 'payment-123',
      tickets: tickets,
      totalAmount: 10000.0,
      purchaseDate: DateTime.now().subtract(const Duration(days: 1)),
      paymentMethod: 'Card',
      paymentStatus: 'completed',
      eventTitle: 'Test Event',
      eventStartTime: DateTime.now().add(const Duration(days: 7)),
      eventVenue: 'Test Venue',
      eventLocation: 'Test Location',
      coverImageUrl: 'https://example.com/image.jpg',
      ticketCount: 2,
      canCancel: canCancel,
      hoursUntilEvent: 168.0,
    );
  }

  static Map<String, dynamic> createMockApiResponse({
    bool success = true,
    int upcomingCount = 2,
    int completedCount = 1,
    int cancelledCount = 0,
  }) {
    return {
      'success': success,
      'tickets': createMockTicketList(),
      'upcoming_payment_groups': [createMockPaymentGroup()],
      'completed_tickets': completedCount > 0 ? createMockTicketList(count: completedCount) : [],
      'cancelled_tickets': cancelledCount > 0 ? createMockTicketList(count: cancelledCount) : [],
      'upcoming_count': upcomingCount,
      'completed_count': completedCount,
      'cancelled_count': cancelledCount,
    };
  }
}
