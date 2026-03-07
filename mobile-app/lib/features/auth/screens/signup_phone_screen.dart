import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_colors.dart';
import '../../../common_widgets/app_screen_header.dart';
import '../../../common_widgets/app_dark_text_field.dart';
import '../../../common_widgets/app_primary_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SignUpPhoneScreen — "Add phone number" screen in the sign-up flow.
// Matches Figma node 2131:24994.
//
// Phone entry is optional — "Skip for now" advances directly to the next step.
// ─────────────────────────────────────────────────────────────────────────────
class SignUpPhoneScreen extends StatefulWidget {
  final String email;
  final String password;

  const SignUpPhoneScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<SignUpPhoneScreen> createState() => _SignUpPhoneScreenState();
}

class _SignUpPhoneScreenState extends State<SignUpPhoneScreen> {
  final _phoneController = TextEditingController();

  bool get _hasInput => _phoneController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (!_hasInput) return;
    final phone = '+62 ${_phoneController.text.trim()}';
    // Navigate to phone verification (dummy)
    context.push('/signup/phone-verification', extra: {
      'email': widget.email,
      'phone': phone,
      'password': widget.password,
    });
  }

  void _handleSkip() {
    // Skip phone → go directly to profile setup
    context.push('/signup/profile', extra: {
      'email': widget.email,
      'phone': '',
      'password': widget.password,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────
            const AppScreenHeader(title: 'Add phone number'),
            const SizedBox(height: 16),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title ──────────────────────────────────────
                    const Text(
                      'Add your phone',
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
                    const Text(
                      'Enter your phone number to get yourself verified and chat with friends',
                      style: TextStyle(
                        fontFamily: appFontFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.2,
                        color: AppColors.grey200,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Phone input with country code ──────────────
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Country flag + code
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Flag placeholder (Indonesia flag emoji)
                                const Text(
                                  '🇮🇩',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '+62',
                                  style: TextStyle(
                                    fontFamily: appFontFamily,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    height: 1.2,
                                    color: AppColors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: AppColors.divider,
                                ),
                              ],
                            ),
                          ),
                          // Phone number input
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              cursorColor: AppColors.primary,
                              style: const TextStyle(
                                fontFamily: appFontFamily,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                height: 1.2,
                                color: AppColors.white,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hintText: 'Enter your phone',
                                hintStyle: TextStyle(
                                  fontFamily: appFontFamily,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  height: 1.2,
                                  color: AppColors.grey200,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                isDense: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Skip for now ───────────────────────────────
                    GestureDetector(
                      onTap: _handleSkip,
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(
                          fontFamily: appFontFamily,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          height: 1.2,
                          color: AppColors.white,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // ── Next button ────────────────────────────────
                    AppPrimaryButton(
                      label: 'Next',
                      onPressed: _hasInput ? _handleNext : null,
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
