import 'package:json_annotation/json_annotation.dart';

// part 'user_model.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profilePicture;
  final String role;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profilePicture,
    required this.role,
    required this.isActive,
    required this.isEmailVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  // Temporary JSON methods
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      profilePicture: json['profile_picture'],
      role: json['role'] ?? 'customer',
      isActive: json['is_active'] ?? true,
      isEmailVerified: json['is_email_verified'] ?? false,
      createdAt: DateTime.now(), // These might not be in the response
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'profile_picture': profilePicture,
      'role': role,
      'is_active': isActive,
      'is_email_verified': isEmailVerified,
    };
  }

  String get fullName => name;

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? profilePicture,
    String? role,
    bool? isActive,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
