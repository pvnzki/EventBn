import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_colors.dart';
import '../../../common_widgets/app_screen_header.dart';
import '../../../common_widgets/app_otp_field.dart';
import '../../../common_widgets/app_primary_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SignUpVerificationScreen — dummy OTP verification screen.
// Reused for both email and phone verification.
// Matches Figma nodes 2131:24429/24615 (email) and 2131:24705 (phone).
//
// This screen is DUMMY — no backend call is made. After entering any 6-digit
// code the user is advanced to the next step.
// ─────────────────────────────────────────────────────────────────────────────
class SignUpVerificationScreen extends StatefulWidget {
  /// `'email'` or `'phone'`
  final String verificationType;

  /// The email address or phone number the code was "sent" to.
  final String destination;

  /// The email collected earlier in the flow (needed to pass forward).
  final String? email;

  /// The password collected from the password-creation step (phone flow).
  final String? password;

  const SignUpVerificationScreen({
    super.key,
    required this.verificationType,
    required this.destination,
    this.email,
    this.password,
  });

  @override
  State<SignUpVerificationScreen> createState() =>
      _SignUpVerificationScreenState();
}

class _SignUpVerificationScreenState extends State<SignUpVerificationScreen> {
  String _code = '';
  int _resendSeconds = 66; // 01:06 as shown in Figma
  Timer? _resendTimer;

  bool get _codeComplete => _code.length == 6;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendSeconds = 66;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds <= 0) {
        timer.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _formattedTimer {
    final m = (_resendSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_resendSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _handleNext() {
    if (!_codeComplete) return;

    if (widget.verificationType == 'email') {
      // After email verification → go to password creation screen
      context.push('/signup/password', extra: {
        'email': widget.destination,
        'phone': '',
      });
    } else {
      // After phone verification → go to password creation screen
      context.push('/signup/password', extra: {
        'email': widget.email ?? '',
        'phone': widget.destination,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmail = widget.verificationType == 'email';
    final sentToLabel =
        isEmail ? 'We sent a verification code to email' : 'We sent a verification code to';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────
            AppScreenHeader(title: 'Verification'),
            const SizedBox(height: 16),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title ──────────────────────────────────────
                    const Text(
                      'Enter code',
                      style: TextStyle(
                        fontFamily: appFontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                        height: 28 / 20,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Subtitle ───────────────────────────────────
                    Text(
                      sentToLabel,
                      style: const TextStyle(
                        fontFamily: appFontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.2,
                        color: AppColors.grey200,
                      ),
                    ),
                    Text(
                      widget.destination,
                      style: const TextStyle(
                        fontFamily: appFontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.2,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── OTP Field ──────────────────────────────────
                    AppOtpField(
                      onChanged: (code) => setState(() => _code = code),
                      onCompleted: (_) {},
                    ),
                    const SizedBox(height: 16),

                    // ── Resend timer ───────────────────────────────
                    if (_resendSeconds > 0)
                      Text(
                        'Resend Code in  $_formattedTimer',
                        style: const TextStyle(
                          fontFamily: appFontFamily,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          height: 1.2,
                          color: AppColors.grey200,
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _startResendTimer,
                        child: const Text(
                          'Resend Code',
                          style: TextStyle(
                            fontFamily: appFontFamily,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            height: 1.2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                    const Spacer(),

                    // ── Next button ────────────────────────────────
                    AppPrimaryButton(
                      label: 'Next',
                      onPressed: _codeComplete ? _handleNext : null,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
