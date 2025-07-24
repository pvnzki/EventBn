import 'package:json_annotation/json_annotation.dart';

// part 'ticket_model.g.dart';

@JsonSerializable()
class Ticket {
  final String id;
  final String eventId;
  final String eventTitle;
  final String eventImageUrl;
  final String userId;
  final String ticketTypeId;
  final String ticketTypeName;
  final double price;
  final int quantity;
  final double totalAmount;
  final String qrCode;
  final TicketStatus status;
  final DateTime purchaseDate;
  final DateTime eventStartDate;
  final String venue;
  final String address;

  const Ticket({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.eventImageUrl,
    required this.userId,
    required this.ticketTypeId,
    required this.ticketTypeName,
    required this.price,
    required this.quantity,
    required this.totalAmount,
    required this.qrCode,
    required this.status,
    required this.purchaseDate,
    required this.eventStartDate,
    required this.venue,
    required this.address,
  });

  // Temporary JSON methods
  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] ?? '',
      eventId: json['eventId'] ?? '',
      eventTitle: json['eventTitle'] ?? '',
      eventImageUrl: json['eventImageUrl'] ?? '',
      userId: json['userId'] ?? '',
      ticketTypeId: json['ticketTypeId'] ?? '',
      ticketTypeName: json['ticketTypeName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      qrCode: json['qrCode'] ?? '',
      status: TicketStatus.values.firstWhere(
        (s) => s.toString().split('.').last == json['status'],
        orElse: () => TicketStatus.active,
      ),
      purchaseDate: json['purchaseDate'] != null ? DateTime.parse(json['purchaseDate']) : DateTime.now(),
      eventStartDate: json['eventStartDate'] != null ? DateTime.parse(json['eventStartDate']) : DateTime.now(),
      venue: json['venue'] ?? '',
      address: json['address'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'eventImageUrl': eventImageUrl,
      'userId': userId,
      'ticketTypeId': ticketTypeId,
      'ticketTypeName': ticketTypeName,
      'price': price,
      'quantity': quantity,
      'totalAmount': totalAmount,
      'qrCode': qrCode,
      'status': status.toString().split('.').last,
      'purchaseDate': purchaseDate.toIso8601String(),
      'eventStartDate': eventStartDate.toIso8601String(),
      'venue': venue,
      'address': address,
    };
  }

  bool get isUpcoming => eventStartDate.isAfter(DateTime.now());
  bool get isPast => eventStartDate.isBefore(DateTime.now());
  bool get isActive => status == TicketStatus.active;
}

enum TicketStatus {
  @JsonValue('active')
  active,
  @JsonValue('used')
  used,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('refunded')
  refunded,
}
