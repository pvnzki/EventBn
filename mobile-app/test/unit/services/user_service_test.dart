import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:event_booking_app/features/profile/services/user_service.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockClient = MockHttpClient();
    UserService.configureForTest(client: mockClient, baseUrl: 'http://test-api');
  });

  group('UserService.getUserById', () {
    test('returns user map on 200 success with valid payload', () async {
      // Arrange
      const userId = '123';
      final responseBody = jsonEncode({
        'success': true,
        'data': {'id': userId, 'name': 'Lisa Sim', 'email': 'lisa@example.com'}
      });

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final service = UserService();

      // Act
      final result = await service.getUserById(userId);

      // Assert
      expect(result, isA<Map<String, dynamic>>());
      expect(result!['email'], 'lisa@example.com');
    });

    test('returns null on 404 not found', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      final result = await UserService().getUserById('999');
      expect(result, isNull);
    });

    test('returns null on invalid response structure', () async {
      final badBody = jsonEncode({'success': true, 'data': null});
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(badBody, 200));

      final result = await UserService().getUserById('123');
      expect(result, isNull);
    });

    test('returns null on exception', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(Exception('network'));

      final result = await UserService().getUserById('123');
      expect(result, isNull);
    });
  });

  group('UserService.getAllUsers', () {
    test('returns list of users on success', () async {
      final responseBody = jsonEncode({
        'success': true,
        'data': [
          {'id': '1', 'name': 'A'},
          {'id': '2', 'name': 'B'}
        ]
      });

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final list = await UserService().getAllUsers(page: 2, limit: 5, search: 'ab');
      expect(list, isA<List<Map<String, dynamic>>>());
      expect(list.length, 2);
    });

    test('returns empty list on failure', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('err', 500));

      final list = await UserService().getAllUsers();
      expect(list, isEmpty);
    });

    test('returns empty list on exception', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(Exception('boom'));

      final list = await UserService().getAllUsers();
      expect(list, isEmpty);
    });
  });
}
