// ...existing code...
import 'package:json_annotation/json_annotation.dart';

// part 'event_model.g.dart';

@JsonSerializable()
class Event {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String otherImagesUrl;
  final String category;
  final String venue;
  final String address;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final List<TicketType> ticketTypes;
  final String organizationId;
  final String organizerName;
  final Map<String, dynamic>? organization;
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
    required this.otherImagesUrl,
    required this.category,
    required this.venue,
    required this.address,
    required this.startDateTime,
    required this.endDateTime,
    required this.ticketTypes,
    required this.organizationId,
    required this.organizerName,
    this.organization,
    required this.totalCapacity,
    required this.soldTickets,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert from API response format
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['event_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['cover_image_url'] ?? '',
      otherImagesUrl: json['other_images_url'] ?? '',
      category: json['category'] ?? '',
      venue: json['venue'] ?? '',
      address: json['location'] ?? '',
      startDateTime: json['start_time'] != null
        ? DateTime.parse(json['start_time'])
        : DateTime.now(),
      endDateTime: json['end_time'] != null
        ? DateTime.parse(json['end_time'])
        : DateTime.now(),
      ticketTypes: [], // TODO: Add ticket types when implemented
      organizationId: json['organization']?['organization_id']?.toString() ?? 
        json['creator']?['user_id']?.toString() ?? '',
      organizerName: json['organization']?['name'] ?? 
             json['creator']?['name'] ?? 'Unknown Organizer',
      organization: json['organization'],
      totalCapacity: json['capacity'] ?? 0,
      soldTickets: 0, // TODO: Add when ticket sales are implemented
      isActive: json['status'] == 'published',
      createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'])
        : DateTime.now(),
      updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'])
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': id,
      'title': title,
      'description': description,
      'cover_image_url': imageUrl,
      'other_images_url': otherImagesUrl,
      'category': category,
      'venue': venue,
      'location': address,
      'start_time': startDateTime.toIso8601String(),
      'end_time': endDateTime.toIso8601String(),
      'ticket_types': ticketTypes.map((e) => e.toJson()).toList(),
      'organization_id': organizationId,
      'organizerName': organizerName,
      'organization': organization,
      'capacity': totalCapacity,
      'soldTickets': soldTickets,
      'status': isActive ? 'published' : 'draft',
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
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
