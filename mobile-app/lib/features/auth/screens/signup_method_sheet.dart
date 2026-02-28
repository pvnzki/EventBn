import 'package:flutter/material.dart';

import '../../../common_widgets/app_colors.dart';
import '../../../common_widgets/app_bottom_sheet.dart';
import '../../../common_widgets/app_primary_button.dart';
import '../../../common_widgets/app_divider_with_text.dart';
import '../../../common_widgets/app_social_icon_button.dart';
import 'signup_email_sheet.dart';
import 'signup_phone_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SignUpMethodSheet — "Let's Get Started" bottom sheet for sign-up method.
// Matches Figma node 2131:24222.
// ─────────────────────────────────────────────────────────────────────────────
class SignUpMethodSheet extends StatelessWidget {
  const SignUpMethodSheet({super.key});

  /// Convenience helper to present the sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => const AppBottomSheet(child: _SheetContent()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const AppBottomSheet(child: _SheetContent());
  }
}

class _SheetContent extends StatelessWidget {
  const _SheetContent();

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

        // ── Continue with Email ─────────────────────────────────
        AppPrimaryButton(
          label: 'Continue with Email',
          onPressed: () {
            final nav = Navigator.of(context);
            // Use the root context (behind the modal) for the next sheet
            final rootCtx = Navigator.of(context, rootNavigator: true).context;
            nav.pop();
            SignUpEmailSheet.show(rootCtx);
          },
        ),
        const SizedBox(height: 12),

        // ── Continue with Phone ─────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              final nav = Navigator.of(context);
              final rootCtx = Navigator.of(context, rootNavigator: true).context;
              nav.pop();
              SignUpPhoneSheet.show(rootCtx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Continue with Phone',
              style: TextStyle(
                fontFamily: appFontFamily,
                fontWeight: FontWeight.w500,
                fontSize: 16,
                height: 1.2,
              ),
            ),
          ),
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
