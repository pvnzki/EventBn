import 'package:json_annotation/json_annotation.dart';

// part 'user_model.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Temporary JSON methods
  factory User.fromJson(Map<String, dynamic> json) {
    // Split name into firstName and lastName
    String fullName = json['name'] ?? '';
    List<String> nameParts = fullName.trim().split(' ');
    String firstName = nameParts.isNotEmpty ? nameParts.first : '';
    String lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
    
    return User(
      id: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      firstName: firstName,
      lastName: lastName,
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phoneNumber'],
      profileImageUrl: json['profile_picture'] ?? json['profileImageUrl'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null 
              ? DateTime.parse(json['createdAt'])
              : DateTime.now()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : (json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': int.tryParse(id) ?? id,
      'name': '$firstName $lastName'.trim(),
      'email': email,
      'phone_number': phoneNumber,
      'profile_picture': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName';

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
