import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_colors.dart';
import '../../../common_widgets/app_primary_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SignUpSuccessScreen — "Account activated!" screen.
// Matches Figma node 2131:24966.
// ─────────────────────────────────────────────────────────────────────────────
class SignUpSuccessScreen extends StatelessWidget {
  const SignUpSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Illustration ─────────────────────────────────────
              _buildIllustration(),
              const SizedBox(height: 32),

              // ── Title ────────────────────────────────────────────
              const Text(
                'Account activated!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: appFontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                  height: 28 / 20,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 8),

              // ── Subtitle ─────────────────────────────────────────
              const SizedBox(
                width: 261,
                child: Text(
                  'Now you can freely search for event tickets as you wish',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: appFontFamily,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    height: 1.2,
                    color: AppColors.grey200,
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // ── Get started button ───────────────────────────────
              AppPrimaryButton(
                label: 'Get started',
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Image.asset(
      'assets/images/success vector.png',
      width: 180,
      height: 180,
      errorBuilder: (_, __, ___) => Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withOpacity(0.08),
        ),
        child: const Icon(
          Icons.check_circle,
          color: AppColors.primary,
          size: 80,
        ),
      ),
    );
  }
}
