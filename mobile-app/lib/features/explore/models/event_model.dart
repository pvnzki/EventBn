class ExploreEvent {
  final String id;
  final String name;
  final String imageUrl;
  final String location;
  final DateTime date;
  final String category;
  final double price;
  final String? badge; // "Trending", "New", "Featured", etc.
  final int attendees;
  final bool isVerified;
  final double rating;

  const ExploreEvent({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.location,
    required this.date,
    required this.category,
    required this.price,
    this.badge,
    required this.attendees,
    this.isVerified = false,
    required this.rating,
  });

  factory ExploreEvent.fromJson(Map<String, dynamic> json) {
    return ExploreEvent(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      location: json['location'] as String,
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      badge: json['badge'] as String?,
      attendees: json['attendees'] as int,
      isVerified: json['isVerified'] as bool? ?? false,
      rating: (json['rating'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'location': location,
      'date': date.toIso8601String(),
      'category': category,
      'price': price,
      'badge': badge,
      'attendees': attendees,
      'isVerified': isVerified,
      'rating': rating,
    };
  }
}

enum ExploreEventCategory {
  all('All'),
  music('Music'),
  sports('Sports'),
  tech('Tech'),
  food('Food'),
  art('Art'),
  business('Business'),
  education('Education');

  const ExploreEventCategory(this.label);
  final String label;
}
