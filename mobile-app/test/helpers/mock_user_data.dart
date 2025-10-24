/// Helpers for building mock user JSON payloads for tests.
Map<String, dynamic> createMockUserJson({
  String id = '142',
  String name = 'Lisa Sim',
  String email = 'lisa@example.com',
  String? phoneNumber = '+94771234567',
  String? profilePicture = 'https://example.com/pic.jpg',
  String createdAt = '2025-10-20T10:53:01.189Z',
  String updatedAt = '2025-10-21T10:53:01.189Z',
  String? billingAddress = '221B Baker Street',
  String? billingCity = 'Colombo',
  String? billingState = 'Western',
  String? billingCountry = 'LK',
  String? billingPostalCode = '00700',
  bool profileCompleted = true,
  String? dateOfBirth = '1995-06-15T00:00:00.000Z',
  String? emergencyName = 'Marge Simpson',
  String? emergencyPhone = '+94770000000',
  String? emergencyRelationship = 'Mother',
  bool marketingEmailsEnabled = true,
  bool eventNotificationsEnabled = true,
  bool smsNotificationsEnabled = true,
}) {
  return {
    'user_id': id,
    'name': name,
    'email': email,
    'phone_number': phoneNumber,
    'profile_picture': profilePicture,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'billing_address': billingAddress,
    'billing_city': billingCity,
    'billing_state': billingState,
    'billing_country': billingCountry,
    'billing_postal_code': billingPostalCode,
    'profile_completed': profileCompleted,
    'date_of_birth': dateOfBirth,
    'emergency_contact_name': emergencyName,
    'emergency_contact_phone': emergencyPhone,
    'emergency_contact_relationship': emergencyRelationship,
    'marketing_emails_enabled': marketingEmailsEnabled,
    'event_notifications_enabled': eventNotificationsEnabled,
    'sms_notifications_enabled': smsNotificationsEnabled,
  };
}

Map<String, dynamic> createMockUserApiResponse({
  Map<String, dynamic>? user,
  bool success = true,
}) {
  return {
    'success': success,
    'data': user ?? createMockUserJson(),
  };
}

List<Map<String, dynamic>> createMockUsersList({int count = 3}) {
  return List.generate(count, (i) => createMockUserJson(id: '${100 + i}', name: 'User $i'));
}
