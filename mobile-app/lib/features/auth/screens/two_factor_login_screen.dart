import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../common_widgets/app_colors.dart';
import '../../../common_widgets/app_screen_header.dart';
import '../../../common_widgets/app_otp_field.dart';
import '../../../common_widgets/app_primary_button.dart';
import '../providers/auth_provider.dart';
import '../services/two_factor_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TwoFactorLoginScreen — 2FA verification step during sign-in.
//
// Shown when the backend returns `requiresTwoFactor: true`.
// Supports authenticator-app codes and email OTP (toggle).
// Dark-themed, consistent with the new sign-up verification UI.
// ─────────────────────────────────────────────────────────────────────────────
class TwoFactorLoginScreen extends StatefulWidget {
  final String email;
  final String password;
  final String? twoFactorMethod;

  const TwoFactorLoginScreen({
    super.key,
    required this.email,
    required this.password,
    this.twoFactorMethod,
  });

  @override
  State<TwoFactorLoginScreen> createState() => _TwoFactorLoginScreenState();
}

class _TwoFactorLoginScreenState extends State<TwoFactorLoginScreen> {
  final _twoFactorService = TwoFactorService();
  String _code = '';
  bool _isLoading = false;
  bool _useEmailOTP = false;
  String? _errorMessage;
  String? _developmentOTP;

  // Resend timer for email OTP
  int _resendSeconds = 0;
  Timer? _resendTimer;

  bool get _codeComplete => _code.length == 6;

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendSeconds = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds <= 0) {
        timer.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  String get _formattedTimer {
    final m = (_resendSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_resendSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Verify code ─────────────────────────────────────────────────────────
  Future<void> _handleVerify() async {
    if (!_codeComplete) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> result;

      if (_useEmailOTP) {
        result = await _twoFactorService.verifyEmailOTP(
          widget.email,
          widget.password,
          _code,
        );
      } else {
        result = await _twoFactorService.verifyTwoFactorLogin(
          widget.email,
          widget.password,
          _code,
        );
      }

      if (!mounted) return;

      if (result['success'] == true) {
        final authProvider = context.read<AuthProvider>();
        await authProvider.completeTwoFactorLogin(result);
        if (!mounted) return;
        context.go('/home');
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Invalid verification code';
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Network error. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Send email OTP ──────────────────────────────────────────────────────
  Future<void> _sendEmailOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _twoFactorService.sendEmailOTP(
        widget.email,
        widget.password,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _useEmailOTP = true;
          if (result['otp'] != null) _developmentOTP = result['otp'];
        });
        _startResendTimer();
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to send OTP';
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Network error. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────
            const AppScreenHeader(title: 'Verification'),
            const SizedBox(height: 16),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title ──────────────────────────────────────
                    const Text(
                      'Enter verification code',
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
                      _useEmailOTP
                          ? 'Enter the 6-digit code sent to your email'
                          : 'Enter the 6-digit code from your authenticator app',
                      style: const TextStyle(
                        fontFamily: appFontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.2,
                        color: AppColors.grey200,
                      ),
                    ),
                    Text(
                      widget.email,
                      style: const TextStyle(
                        fontFamily: appFontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.2,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Dev OTP display ────────────────────────────
                    if (_developmentOTP != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Dev OTP: $_developmentOTP',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: appFontFamily,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── OTP Field ──────────────────────────────────
                    AppOtpField(
                      onChanged: (code) => setState(() {
                        _code = code;
                        if (_errorMessage != null) _errorMessage = null;
                      }),
                      onCompleted: (_) => _handleVerify(),
                    ),
                    const SizedBox(height: 16),

                    // ── Error message ──────────────────────────────
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontFamily: appFontFamily,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            height: 1.2,
                            color: AppColors.dangerText,
                          ),
                        ),
                      ),

                    // ── Resend / method toggle ─────────────────────
                    if (_useEmailOTP && _resendSeconds > 0)
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
                    else if (_useEmailOTP)
                      GestureDetector(
                        onTap: _isLoading ? null : _sendEmailOTP,
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

                    const SizedBox(height: 16),

                    // ── Switch method ──────────────────────────────
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              if (_useEmailOTP) {
                                setState(() {
                                  _useEmailOTP = false;
                                  _developmentOTP = null;
                                  _code = '';
                                  _errorMessage = null;
                                });
                              } else {
                                _sendEmailOTP();
                              }
                            },
                      child: Text(
                        _useEmailOTP
                            ? 'Use Authenticator App instead'
                            : 'Send code via Email instead',
                        style: const TextStyle(
                          fontFamily: appFontFamily,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          height: 1.2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // ── Verify button ──────────────────────────────
                    AppPrimaryButton(
                      label: 'Verify & Login',
                      onPressed: _codeComplete ? _handleVerify : null,
                      isLoading: _isLoading,
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
