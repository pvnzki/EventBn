import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_colors.dart';
import '../../../common_widgets/app_screen_header.dart';
import '../../../common_widgets/app_dark_text_field.dart';
import '../../../common_widgets/app_primary_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SignUpPasswordScreen — Password creation step in the sign-up flow.
//
// Shown after email/phone verification. Collects & validates a strong password
// before forwarding it to the next step (phone entry or profile setup).
//
// Security practices applied:
//   • Min 8 chars, upper + lower + digit + special character
//   • Password confirmation must match
//   • Real-time visual strength indicator per rule
//   • Text is obscured by default with toggle
//   • Password is never logged or persisted on-device
// ─────────────────────────────────────────────────────────────────────────────
class SignUpPasswordScreen extends StatefulWidget {
  /// The email collected earlier (empty for phone-first flow).
  final String email;

  /// The phone collected earlier (empty for email-first flow).
  final String phone;

  const SignUpPasswordScreen({
    super.key,
    required this.email,
    required this.phone,
  });

  @override
  State<SignUpPasswordScreen> createState() => _SignUpPasswordScreenState();
}

class _SignUpPasswordScreenState extends State<SignUpPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // ── Validation helpers ──────────────────────────────────────────────────

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUpperCase =>
      _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowerCase =>
      _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasDigit => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial =>
      _passwordController.text.contains(RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:,.<>?/\\|`~]'));

  bool get _passwordsMatch =>
      _passwordController.text.isNotEmpty &&
      _confirmController.text.isNotEmpty &&
      _passwordController.text == _confirmController.text;

  bool get _allRulesPass =>
      _hasMinLength &&
      _hasUpperCase &&
      _hasLowerCase &&
      _hasDigit &&
      _hasSpecial;

  bool get _isFormValid => _allRulesPass && _passwordsMatch;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onChanged);
    _confirmController.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── Navigation ──────────────────────────────────────────────────────────

  void _handleContinue() {
    if (!_isFormValid) return;

    final password = _passwordController.text;

    if (widget.email.isNotEmpty && widget.phone.isEmpty) {
      // Email-first flow → next: add phone number
      context.push('/signup/phone', extra: {
        'email': widget.email,
        'password': password,
      });
    } else {
      // Phone-first flow → next: profile setup
      context.push('/signup/profile', extra: {
        'email': widget.email,
        'phone': widget.phone,
        'password': password,
      });
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppScreenHeader(title: 'Create password'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Title ─────────────────────────────────────
                    const Text(
                      'Create a password',
                      style: TextStyle(
                        fontFamily: appFontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                        height: 28 / 20,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your password must meet all the requirements below',
                      style: TextStyle(
                        fontFamily: appFontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.2,
                        color: AppColors.grey200,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Password field ────────────────────────────
                    _buildLabel('Password'),
                    const SizedBox(height: 8),
                    AppDarkTextField(
                      controller: _passwordController,
                      placeholder: 'Enter your password',
                      obscureText: _obscurePassword,
                      suffix: _buildEyeToggle(
                        obscured: _obscurePassword,
                        onTap: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Confirm password field ────────────────────
                    _buildLabel('Confirm password'),
                    const SizedBox(height: 8),
                    AppDarkTextField(
                      controller: _confirmController,
                      placeholder: 'Re-enter your password',
                      obscureText: _obscureConfirm,
                      hasError: _confirmController.text.isNotEmpty &&
                          !_passwordsMatch,
                      suffix: _buildEyeToggle(
                        obscured: _obscureConfirm,
                        onTap: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),

                    // ── Match error ───────────────────────────────
                    if (_confirmController.text.isNotEmpty && !_passwordsMatch)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Passwords do not match',
                          style: TextStyle(
                            fontFamily: appFontFamily,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: AppColors.dangerText,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // ── Strength rules ────────────────────────────
                    _buildRule('At least 8 characters', _hasMinLength),
                    _buildRule('One uppercase letter (A-Z)', _hasUpperCase),
                    _buildRule('One lowercase letter (a-z)', _hasLowerCase),
                    _buildRule('One digit (0-9)', _hasDigit),
                    _buildRule(
                        'One special character (!@#\$%^&*)', _hasSpecial),
                    const SizedBox(height: 32),

                    // ── Continue button ───────────────────────────
                    AppPrimaryButton(
                      label: 'Continue',
                      onPressed: _isFormValid ? _handleContinue : null,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: appFontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        height: 1.2,
        color: AppColors.grey200,
      ),
    );
  }

  Widget _buildEyeToggle({
    required bool obscured,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        'assets/icons/eye closed.png',
        width: 24,
        height: 24,
        color: obscured ? AppColors.grey300 : AppColors.primary,
        errorBuilder: (_, __, ___) => Icon(
          obscured ? Icons.visibility_off : Icons.visibility,
          color: obscured ? AppColors.grey300 : AppColors.primary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildRule(String text, bool passed) {
    final hasInput = _passwordController.text.isNotEmpty;
    final Color iconColor;
    final Color textColor;

    if (!hasInput) {
      iconColor = AppColors.grey300;
      textColor = AppColors.grey300;
    } else if (passed) {
      iconColor = AppColors.primary;
      textColor = AppColors.primary;
    } else {
      iconColor = AppColors.dangerText;
      textColor = AppColors.dangerText;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            passed && hasInput ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontFamily: appFontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 13,
              height: 1.2,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
