import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_colors.dart';
import '../../../common_widgets/app_bottom_sheet.dart';
import '../../../common_widgets/app_dark_text_field.dart';
import '../../../common_widgets/app_primary_button.dart';
import '../../../common_widgets/app_divider_with_text.dart';
import '../../../common_widgets/app_social_icon_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SignUpEmailSheet — bottom sheet for entering email to sign up.
// Matches Figma nodes 2131:24291 (empty) and 2131:24360 (filled).
// ─────────────────────────────────────────────────────────────────────────────
class SignUpEmailSheet extends StatelessWidget {
  const SignUpEmailSheet({super.key});

  /// Convenience helper to present the sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => const AppBottomSheet(child: _EmailSheetContent()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const AppBottomSheet(child: _EmailSheetContent());
  }
}

class _EmailSheetContent extends StatefulWidget {
  const _EmailSheetContent();

  @override
  State<_EmailSheetContent> createState() => _EmailSheetContentState();
}

class _EmailSheetContentState extends State<_EmailSheetContent> {
  final _emailController = TextEditingController();

  bool get _hasInput => _emailController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (!_hasInput) return;
    final email = _emailController.text.trim();
    // Capture the GoRouter BEFORE popping the modal — the bottom-sheet
    // context becomes invalid after pop.
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push('/signup/verification', extra: {
      'type': 'email',
      'destination': email,
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

        // ── Email field ─────────────────────────────────────────
        AppDarkTextField(
          controller: _emailController,
          placeholder: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
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
