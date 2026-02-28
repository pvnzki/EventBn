import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_colors.dart';
import '../../../common_widgets/app_bottom_sheet.dart';
import '../../../common_widgets/app_primary_button.dart';
import '../../../common_widgets/app_divider_with_text.dart';
import '../../../common_widgets/app_social_icon_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SignUpPhoneSheet — bottom sheet for entering phone number to sign up.
// Shown when user selects "Continue with Phone" on the method sheet.
// Flow: phone entry → phone verification (dummy) → profile setup → success.
// ─────────────────────────────────────────────────────────────────────────────
class SignUpPhoneSheet extends StatelessWidget {
  const SignUpPhoneSheet({super.key});

  /// Convenience helper to present the sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => const AppBottomSheet(child: _PhoneSheetContent()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const AppBottomSheet(child: _PhoneSheetContent());
  }
}

class _PhoneSheetContent extends StatefulWidget {
  const _PhoneSheetContent();

  @override
  State<_PhoneSheetContent> createState() => _PhoneSheetContentState();
}

class _PhoneSheetContentState extends State<_PhoneSheetContent> {
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

  void _handleContinue() {
    if (!_hasInput) return;
    final phone = '+62 ${_phoneController.text.trim()}';
    // Capture GoRouter BEFORE popping — modal context dies after pop.
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push('/signup/verification', extra: {
      'type': 'phone',
      'destination': phone,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ──────────────────────────────────────────
        Row(
          children: [
            const Expanded(
              child: Text(
                "Let's Get Started",
                style: TextStyle(
                  fontFamily: appFontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                  height: 28 / 20,
                  color: AppColors.white,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Image.asset(
                'assets/icons/Close.png',
                width: 24,
                height: 24,
                color: AppColors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Description ─────────────────────────────────────────
        const Text(
          "Get an account and find your event wherever you are or wherever you're going",
          style: TextStyle(
            fontFamily: appFontFamily,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            height: 1.2,
            color: AppColors.grey200,
          ),
        ),
        const SizedBox(height: 24),

        // ── Phone input with country code ───────────────────────
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
                    const Text('🇮🇩', style: TextStyle(fontSize: 18)),
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
                    hintText: 'Enter your phone number',
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
        const SizedBox(height: 12),

        // ── Continue button ─────────────────────────────────────
        AppPrimaryButton(
          label: 'Continue',
          onPressed: _hasInput ? _handleContinue : null,
        ),
        const SizedBox(height: 24),

        // ── "or sign in with" divider ───────────────────────────
        const AppDividerWithText(text: 'or sign in with'),
        const SizedBox(height: 24),

        // ── Social sign-in row ──────────────────────────────────
        AppSocialSignInRow(
          onSocialTap: (provider) {
            // TODO: implement social sign-up per provider
          },
        ),
        const SizedBox(height: 24),

        // ── Terms & Privacy ─────────────────────────────────────
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontFamily: appFontFamily,
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: AppColors.grey200,
              ),
              children: [
                TextSpan(
                    text:
                        'By signing up you acknowledge and agree to event.com '),
                TextSpan(
                  text: 'General Terms of Use',
                  style: TextStyle(color: AppColors.primary),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
