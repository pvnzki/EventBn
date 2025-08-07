import 'package:json_annotation/json_annotation.dart';

// Organization model to match backend response
class Organization {
  final int organizationId;
  final String name;
  final String? description;
  final String? type;
  final String? email;
  final String? phone;
  final String? address;
  final String? website;
  final String? logo;
  final String? status;
  final DateTime? createdAt;

  const Organization({
    required this.organizationId,
    required this.name,
    this.description,
    this.type,
    this.email,
    this.phone,
    this.address,
    this.website,
    this.logo,
    this.status,
    this.createdAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      organizationId: json['organization_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      type: json['type'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      website: json['website'],
      logo: json['logo'],
      status: json['status'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organization_id': organizationId,
      'name': name,
      'description': description,
      'type': type,
      'email': email,
      'phone': phone,
      'address': address,
      'website': website,
      'logo': logo,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

// part 'event_model.g.dart';

@JsonSerializable()
class Event {
  final int eventId;
  final int? organizationId;
  final String title;
  final String? description;
  final String? category;
  final String? venue;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final int? capacity;
  final String? status;
  final String? coverImageUrl;
  final String? otherImagesUrl;
  final DateTime? createdAt;
  final Organization? organization;

  const Event({
    required this.eventId,
    this.organizationId,
    required this.title,
    this.description,
    this.category,
    this.venue,
    this.location,
    required this.startTime,
    required this.endTime,
    this.capacity,
    this.status,
    this.coverImageUrl,
    this.otherImagesUrl,
    this.createdAt,
    this.organization,
  });

  // Temporary JSON methods
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      eventId: json['event_id'] ?? 0,
      organizationId: json['organization_id'],
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'],
      venue: json['venue'],
      location: json['location'],
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : DateTime.now(),
      capacity: json['capacity'],
      status: json['status'],
      coverImageUrl: json['cover_image_url'],
      otherImagesUrl: json['other_images_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      organization: json['organization'] != null
          ? Organization.fromJson(json['organization'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'organization_id': organizationId,
      'title': title,
      'description': description,
      'category': category,
      'venue': venue,
      'location': location,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'capacity': capacity,
      'status': status,
      'cover_image_url': coverImageUrl,
      'other_images_url': otherImagesUrl,
      'created_at': createdAt?.toIso8601String(),
      'organization': organization?.toJson(),
    };
  }

  // Helper getters based on available fields
  bool get hasCapacity => capacity != null && capacity! > 0;
  bool get isActive => status == 'active';
  String get organizerName => organization?.name ?? 'Unknown Organizer';
  String get displayLocation => location ?? venue ?? 'TBD';
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
