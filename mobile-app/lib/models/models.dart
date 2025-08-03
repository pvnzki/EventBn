class User {
  final int userId;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? profilePicture;
  final String role;
  final bool isActive;
  final bool isEmailVerified;

  User({
    required this.userId,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.profilePicture,
    required this.role,
    required this.isActive,
    required this.isEmailVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] ?? json['id'],
      email: json['email'],
      name: json['name'],
      phoneNumber: json['phone_number'] ?? json['phone'],
      profilePicture: json['profile_picture'],
      role: json['role'] ?? 'customer',
      isActive: json['is_active'] ?? true,
      isEmailVerified: json['is_email_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'name': name,
      'phone_number': phoneNumber,
      'profile_picture': profilePicture,
      'role': role,
      'is_active': isActive,
      'is_email_verified': isEmailVerified,
    };
  }
}

class Event {
  final int eventId;
  final String title;
  final String? description;
  final String? category;
  final String? venue;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final int? capacity;
  final String status;
  final String? coverImageUrl;
  final String? otherImagesUrl;
  final DateTime? createdAt;
  final int? organizerId;
  final int? organizationId;

  Event({
    required this.eventId,
    required this.title,
    this.description,
    this.category,
    this.venue,
    this.location,
    required this.startTime,
    required this.endTime,
    this.capacity,
    required this.status,
    this.coverImageUrl,
    this.otherImagesUrl,
    this.createdAt,
    this.organizerId,
    this.organizationId,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      eventId: json['event_id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      venue: json['venue'],
      location: json['location'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      capacity: json['capacity'],
      status: json['status'],
      coverImageUrl: json['cover_image_url'],
      otherImagesUrl: json['other_images_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      organizerId: json['organizer_id'],
      organizationId: json['organization_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
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
      'organizer_id': organizerId,
      'organization_id': organizationId,
    };
  }
}

class Order {
  final int orderId;
  final int? userId;
  final int? eventId;
  final DateTime? orderDate;
  final double? totalAmount;
  final String? transactionId;
  final int? ticketCount;

  Order({
    required this.orderId,
    this.userId,
    this.eventId,
    this.orderDate,
    this.totalAmount,
    this.transactionId,
    this.ticketCount,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'],
      userId: json['user_id'],
      eventId: json['event_id'],
      orderDate: json['order_date'] != null
          ? DateTime.parse(json['order_date'])
          : null,
      totalAmount: json['total_amount'] != null
          ? double.parse(json['total_amount'].toString())
          : null,
      transactionId: json['transaction_id'],
      ticketCount: json['ticket_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'user_id': userId,
      'event_id': eventId,
      'order_date': orderDate?.toIso8601String(),
      'total_amount': totalAmount,
      'transaction_id': transactionId,
      'ticket_count': ticketCount,
    };
  }
}
