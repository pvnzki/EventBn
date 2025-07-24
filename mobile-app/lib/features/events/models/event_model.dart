import 'package:json_annotation/json_annotation.dart';

// part 'event_model.g.dart';

@JsonSerializable()
class Event {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final String venue;
  final String address;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final List<TicketType> ticketTypes;
  final String organizerId;
  final String organizerName;
  final int totalCapacity;
  final int soldTickets;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.venue,
    required this.address,
    required this.startDateTime,
    required this.endDateTime,
    required this.ticketTypes,
    required this.organizerId,
    required this.organizerName,
    required this.totalCapacity,
    required this.soldTickets,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Temporary JSON methods
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      venue: json['venue'] ?? '',
      address: json['address'] ?? '',
      startDateTime: json['startDateTime'] != null
          ? DateTime.parse(json['startDateTime'])
          : DateTime.now(),
      endDateTime: json['endDateTime'] != null
          ? DateTime.parse(json['endDateTime'])
          : DateTime.now(),
      ticketTypes: (json['ticketTypes'] as List?)
              ?.map((e) => TicketType.fromJson(e))
              .toList() ??
          [],
      organizerId: json['organizerId'] ?? '',
      organizerName: json['organizerName'] ?? '',
      totalCapacity: json['totalCapacity'] ?? 0,
      soldTickets: json['soldTickets'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'venue': venue,
      'address': address,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime.toIso8601String(),
      'ticketTypes': ticketTypes.map((e) => e.toJson()).toList(),
      'organizerId': organizerId,
      'organizerName': organizerName,
      'totalCapacity': totalCapacity,
      'soldTickets': soldTickets,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isSoldOut => soldTickets >= totalCapacity;
  int get availableTickets => totalCapacity - soldTickets;
  double get cheapestPrice => ticketTypes.isEmpty
      ? 0.0
      : ticketTypes.map((t) => t.price).reduce((a, b) => a < b ? a : b);
}

@JsonSerializable()
class TicketType {
  final String id;
  final String name;
  final String description;
  final double price;
  final int totalQuantity;
  final int soldQuantity;
  final int maxPerOrder;

  const TicketType({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.totalQuantity,
    required this.soldQuantity,
    required this.maxPerOrder,
  });

  // Temporary JSON methods
  factory TicketType.fromJson(Map<String, dynamic> json) {
    return TicketType(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      totalQuantity: json['totalQuantity'] ?? 0,
      soldQuantity: json['soldQuantity'] ?? 0,
      maxPerOrder: json['maxPerOrder'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'totalQuantity': totalQuantity,
      'soldQuantity': soldQuantity,
      'maxPerOrder': maxPerOrder,
    };
  }

  bool get isAvailable => soldQuantity < totalQuantity;
  int get availableQuantity => totalQuantity - soldQuantity;
}
