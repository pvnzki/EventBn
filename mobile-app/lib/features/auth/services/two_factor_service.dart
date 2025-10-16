import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../core/constants.dart';
import 'auth_service.dart';

class TwoFactorService {
  final String baseUrl = AppConfig.baseUrl;
  final AuthService _authService = AuthService();

  // Generate 2FA QR code for setup
  Future<Map<String, dynamic>> generateTwoFactorQR() async {
    try {
      final token = await _authService.getStoredToken();
      if (token == null) {
        print('❌ [2FA_SERVICE] No token found for QR generation');
        return {'success': false, 'message': 'Not authenticated'};
      }

      final url = '$baseUrl${Constants.authEndpoint}/2fa/generate';
      print('🔄 [2FA_SERVICE] Generating 2FA QR code from: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📦 [2FA_SERVICE] QR generation response status: ${response.statusCode}');
      print('📦 [2FA_SERVICE] QR generation response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ [2FA_SERVICE] QR code generated successfully');
        return {
          'success': true,
          'qrCode': data['qrCode'],
          'secret': data['secret'],
          'backupCodes': data['backupCodes'],
        };
      } else {
        print('❌ [2FA_SERVICE] QR generation failed: ${data['message']}');
        return {'success': false, 'message': data['message'] ?? 'Failed to generate 2FA'};
      }
    } catch (e) {
      print('❌ [2FA_SERVICE] Error generating QR code: $e');
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Verify 2FA token to complete setup
  Future<Map<String, dynamic>> verifyTwoFactorSetup(String token) async {
    try {
      final authToken = await _authService.getStoredToken();
      if (authToken == null) {
        print('❌ [2FA_SERVICE] No token found for verification');
        return {'success': false, 'message': 'Not authenticated'};
      }

      final url = '$baseUrl${Constants.authEndpoint}/2fa/verify';
      print('🔄 [2FA_SERVICE] Verifying 2FA setup with: $url');
      print('📝 [2FA_SERVICE] Token: ${token.substring(0, 2)}***${token.substring(token.length - 2)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': token}),
      );

      print('📦 [2FA_SERVICE] Verification response status: ${response.statusCode}');
      print('📦 [2FA_SERVICE] Verification response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ [2FA_SERVICE] 2FA setup verified successfully');
        return {
          'success': true,
          'backupCodes': data['backupCodes'],
        };
      } else {
        print('❌ [2FA_SERVICE] 2FA verification failed: ${data['message']}');
        return {'success': false, 'message': data['message'] ?? 'Invalid verification code'};
      }
    } catch (e) {
      print('❌ [2FA_SERVICE] Error verifying 2FA setup: $e');
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Disable 2FA
  Future<Map<String, dynamic>> disableTwoFactor(String password) async {
    try {
      final token = await _authService.getStoredToken();
      if (token == null) {
        print('❌ [2FA_SERVICE] No token found for disabling 2FA');
        return {'success': false, 'message': 'Not authenticated'};
      }

      final url = '$baseUrl${Constants.authEndpoint}/2fa/disable';
      print('🔄 [2FA_SERVICE] Disabling 2FA from: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'password': password}),
      );

      print('📦 [2FA_SERVICE] Disable response status: ${response.statusCode}');
      print('📦 [2FA_SERVICE] Disable response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ [2FA_SERVICE] 2FA disabled successfully');
        return {'success': true};
      } else {
        print('❌ [2FA_SERVICE] 2FA disable failed: ${data['message']}');
        return {'success': false, 'message': data['message'] ?? 'Failed to disable 2FA'};
      }
    } catch (e) {
      print('❌ [2FA_SERVICE] Error disabling 2FA: $e');
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Verify 2FA token during login (app-based)
  Future<Map<String, dynamic>> verifyTwoFactorLogin(String email, String password, String twoFactorCode) async {
    try {
      final url = '$baseUrl${Constants.authEndpoint}/login/2fa';
      print('🔄 [2FA_SERVICE] Logging in with 2FA to: $url');
      print('📝 [2FA_SERVICE] Email: $email');
      print('📝 [2FA_SERVICE] 2FA Code: ${twoFactorCode.substring(0, 2)}***${twoFactorCode.substring(twoFactorCode.length - 2)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'twoFactorCode': twoFactorCode,
        }),
      );

      print('📦 [2FA_SERVICE] Login response status: ${response.statusCode}');
      print('📦 [2FA_SERVICE] Login response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ [2FA_SERVICE] 2FA login successful');
        
        return {
          'success': true,
          'user': data['data'] ?? data['user'],
          'token': data['token'],
        };
      } else {
        print('❌ [2FA_SERVICE] 2FA login failed: ${data['message']}');
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      print('❌ [2FA_SERVICE] Error during 2FA login: $e');
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Send email OTP for 2FA
  Future<Map<String, dynamic>> sendEmailOTP(String email, String password) async {
    try {
      final url = '$baseUrl${Constants.authEndpoint}/2fa/send-email-otp';
      print('🔄 [2FA_SERVICE] Sending email OTP to: $url');
      print('📝 [2FA_SERVICE] Email: $email');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('📦 [2FA_SERVICE] Email OTP response status: ${response.statusCode}');
      print('📦 [2FA_SERVICE] Email OTP response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ [2FA_SERVICE] Email OTP sent successfully');
        return {
          'success': true,
          'message': data['message'],
          // For development, include OTP
          if (data['otp'] != null) 'otp': data['otp'],
        };
      } else {
        print('❌ [2FA_SERVICE] Email OTP failed: ${data['message']}');
        return {'success': false, 'message': data['message'] ?? 'Failed to send OTP'};
      }
    } catch (e) {
      print('❌ [2FA_SERVICE] Error sending email OTP: $e');
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Verify email OTP for 2FA login
  Future<Map<String, dynamic>> verifyEmailOTP(String email, String password, String otp) async {
    try {
      final url = '$baseUrl${Constants.authEndpoint}/2fa/verify-email-otp';
      print('🔄 [2FA_SERVICE] Verifying email OTP to: $url');
      print('📝 [2FA_SERVICE] Email: $email');
      print('📝 [2FA_SERVICE] OTP: ${otp.substring(0, 2)}***${otp.substring(otp.length - 2)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'otp': otp,
        }),
      );

      print('📦 [2FA_SERVICE] Email OTP verification response status: ${response.statusCode}');
      print('📦 [2FA_SERVICE] Email OTP verification response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ [2FA_SERVICE] Email OTP verification successful');
        
        return {
          'success': true,
          'user': data['data'] ?? data['user'],
          'token': data['token'],
        };
      } else {
        print('❌ [2FA_SERVICE] Email OTP verification failed: ${data['message']}');
        return {'success': false, 'message': data['message'] ?? 'Invalid OTP'};
      }
    } catch (e) {
      print('❌ [2FA_SERVICE] Error verifying email OTP: $e');
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await _authService.getStoredToken();
      if (token == null) {
        print('❌ [2FA_SERVICE] No token found');
        return {'success': false, 'message': 'Not authenticated'};
      }

      final url = '$baseUrl${Constants.authEndpoint}/change-password';
      print('🔄 [2FA_SERVICE] Making password change request to: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      print('📦 [2FA_SERVICE] Response status: ${response.statusCode}');
      print('📦 [2FA_SERVICE] Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ [2FA_SERVICE] Password changed successfully');
        return {'success': true};
      } else {
        print('❌ [2FA_SERVICE] Password change failed: ${data['message']}');
        return {'success': false, 'message': data['message'] ?? 'Failed to change password'};
      }
    } catch (e) {
      print('❌ [2FA_SERVICE] Error changing password: $e');
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Get user security settings
  Future<Map<String, dynamic>> getSecuritySettings() async {
    try {
      final token = await _authService.getStoredToken();
      if (token == null) {
        print('❌ [2FA_SERVICE] No token found for security settings');
        return {'success': false, 'message': 'Not authenticated'};
      }

      final url = '$baseUrl${Constants.authEndpoint}/security-settings';
      print('🔄 [2FA_SERVICE] Fetching security settings from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📦 [2FA_SERVICE] Security settings response status: ${response.statusCode}');
      print('📦 [2FA_SERVICE] Security settings response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ [2FA_SERVICE] Security settings loaded successfully');
        return {
          'success': true,
          'twoFactorEnabled': data['twoFactorEnabled'] ?? false,
          'lastPasswordChange': data['lastPasswordChange'],
        };
      } else {
        print('❌ [2FA_SERVICE] Security settings failed: ${data['message']}');
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch security settings'};
      }
    } catch (e) {
      print('❌ [2FA_SERVICE] Error fetching security settings: $e');
      return {'success': false, 'message': 'Network error occurred'};
    }
  }
}