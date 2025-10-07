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
  
  // Billing information
  final String? billingAddress;
  final String? billingCity;
  final String? billingState;
  final String? billingCountry;
  final String? billingPostalCode;
  
  // Profile information
  final bool profileCompleted;
  final DateTime? dateOfBirth;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;
  
  // Communication preferences
  final bool marketingEmailsEnabled;
  final bool eventNotificationsEnabled;
  final bool smsNotificationsEnabled;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.billingAddress,
    this.billingCity,
    this.billingState,
    this.billingCountry,
    this.billingPostalCode,
    this.profileCompleted = false,
    this.dateOfBirth,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
    this.marketingEmailsEnabled = true,
    this.eventNotificationsEnabled = true,
    this.smsNotificationsEnabled = true,
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
      billingAddress: json['billing_address'],
      billingCity: json['billing_city'],
      billingState: json['billing_state'], 
      billingCountry: json['billing_country'],
      billingPostalCode: json['billing_postal_code'],
      profileCompleted: json['profile_completed'] ?? false,
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth'])
          : null,
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactPhone: json['emergency_contact_phone'],
      emergencyContactRelationship: json['emergency_contact_relationship'],
      marketingEmailsEnabled: json['marketing_emails_enabled'] ?? true,
      eventNotificationsEnabled: json['event_notifications_enabled'] ?? true,
      smsNotificationsEnabled: json['sms_notifications_enabled'] ?? true,
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
      'billing_address': billingAddress,
      'billing_city': billingCity,
      'billing_state': billingState,
      'billing_country': billingCountry,
      'billing_postal_code': billingPostalCode,
      'profile_completed': profileCompleted,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'emergency_contact_relationship': emergencyContactRelationship,
      'marketing_emails_enabled': marketingEmailsEnabled,
      'event_notifications_enabled': eventNotificationsEnabled,
      'sms_notifications_enabled': smsNotificationsEnabled,
    };
  }

  String get fullName => '$firstName $lastName';

  bool get hasCompleteBillingInfo => 
      phoneNumber != null && phoneNumber!.isNotEmpty &&
      billingAddress != null && billingAddress!.isNotEmpty &&
      billingCity != null && billingCity!.isNotEmpty &&
      billingCountry != null && billingCountry!.isNotEmpty;

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? billingAddress,
    String? billingCity,
    String? billingState,
    String? billingCountry,
    String? billingPostalCode,
    bool? profileCompleted,
    DateTime? dateOfBirth,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
    bool? marketingEmailsEnabled,
    bool? eventNotificationsEnabled,
    bool? smsNotificationsEnabled,
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
      billingAddress: billingAddress ?? this.billingAddress,
      billingCity: billingCity ?? this.billingCity,
      billingState: billingState ?? this.billingState,
      billingCountry: billingCountry ?? this.billingCountry,
      billingPostalCode: billingPostalCode ?? this.billingPostalCode,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelationship: emergencyContactRelationship ?? this.emergencyContactRelationship,
      marketingEmailsEnabled: marketingEmailsEnabled ?? this.marketingEmailsEnabled,
      eventNotificationsEnabled: eventNotificationsEnabled ?? this.eventNotificationsEnabled,
      smsNotificationsEnabled: smsNotificationsEnabled ?? this.smsNotificationsEnabled,
    );
  }
}
