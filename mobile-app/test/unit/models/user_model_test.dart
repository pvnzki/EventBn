import 'package:flutter_test/flutter_test.dart';
import 'package:event_booking_app/features/auth/models/user_model.dart';
import '../../helpers/mock_user_data.dart';

void main() {
  group('User model - fromJson', () {
    test('parses full JSON correctly and splits name', () {
      final json = createMockUserJson(name: 'Lisa Sim', id: '142');
      final user = User.fromJson(json);

      expect(user.id, '142');
      expect(user.firstName, 'Lisa');
      expect(user.lastName, 'Sim');
      expect(user.email, 'lisa@example.com');
      expect(user.phoneNumber, '+94771234567');
      expect(user.profileImageUrl, isNotNull);
      expect(user.createdAt, isA<DateTime>());
      expect(user.updatedAt, isA<DateTime>());
      expect(user.billingAddress, '221B Baker Street');
      expect(user.billingCity, 'Colombo');
      expect(user.billingCountry, 'LK');
      expect(user.profileCompleted, true);
      expect(user.dateOfBirth, isA<DateTime>());
      expect(user.emergencyContactName, 'Marge Simpson');
      expect(user.marketingEmailsEnabled, true);
      expect(user.eventNotificationsEnabled, true);
      expect(user.smsNotificationsEnabled, true);
    });

    test('handles single name with empty lastName', () {
      final json = createMockUserJson(name: 'Prince');
      final user = User.fromJson(json);
      expect(user.firstName, 'Prince');
      expect(user.lastName, '');
    });

    test('handles invalid or missing dob', () {
      final json = createMockUserJson(dateOfBirth: 'not-a-date');
      final user = User.fromJson(json);
      expect(user.dateOfBirth, isNull);

      final json2 = createMockUserJson(dateOfBirth: null);
      final user2 = User.fromJson(json2);
      expect(user2.dateOfBirth, isNull);
    });
  });

  group('User model - toJson', () {
    test('serializes to API shape and keeps numeric user_id', () {
      final user = User.fromJson(createMockUserJson(id: '142'));
      final json = user.toJson();

      expect(json['user_id'], 142); // int parsing
      expect(json['name'], '${user.firstName} ${user.lastName}'.trim());
      expect(json['email'], user.email);
      expect(json['phone_number'], user.phoneNumber);
      expect(json['profile_picture'], user.profileImageUrl);
      expect(json['created_at'], isA<String>());
      expect(json['updated_at'], isA<String>());
      expect(json['billing_address'], user.billingAddress);
      expect(json['profile_completed'], user.profileCompleted);
    });

    test('serializes non-numeric id as string in user_id', () {
      final j = createMockUserJson(id: 'UID-XYZ');
      final user = User.fromJson(j);
      final out = user.toJson();
      expect(out['user_id'], 'UID-XYZ');
    });
  });

  group('User model - helpers', () {
    test('hasCompleteBillingInfo true only when required fields set', () {
      final base = createMockUserJson();
      final user = User.fromJson(base);
      expect(user.hasCompleteBillingInfo, true);

      final incomplete = createMockUserJson(phoneNumber: null);
      final user2 = User.fromJson(incomplete);
      expect(user2.hasCompleteBillingInfo, false);
    });

    test('copyWith updates selected fields', () {
      final user = User.fromJson(createMockUserJson());
      final updated = user.copyWith(
        phoneNumber: '+94112223344',
        billingCity: 'Kandy',
        profileCompleted: false,
      );
      expect(updated.phoneNumber, '+94112223344');
      expect(updated.billingCity, 'Kandy');
      expect(updated.profileCompleted, false);
      // Unchanged
      expect(updated.email, user.email);
      expect(updated.id, user.id);
    });
  });
}
