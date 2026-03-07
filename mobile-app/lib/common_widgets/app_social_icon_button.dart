import 'package:flutter/material.dart';
import 'app_colors.dart';

/// A circular social-provider icon button (Google, Facebook, Apple, X).
///
/// Usage:
/// ```dart
/// AppSocialIconButton(
///   asset: 'assets/icons/google.png',
///   onTap: () { /* sign-in with Google */ },
/// )
/// ```
class AppSocialIconButton extends StatelessWidget {
  final String asset;
  final VoidCallback? onTap;

  /// When `true`, a white `ColorFilter` is applied to the asset image —
  /// useful for monochrome icons like Apple / X that need to appear white.
  final bool applyWhiteTint;

  const AppSocialIconButton({
    super.key,
    required this.asset,
    this.onTap,
    this.applyWhiteTint = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Center(
          child: Image.asset(
            asset,
            width: 25,
            height: 25,
            color: applyWhiteTint ? AppColors.white : null,
          ),
        ),
      ),
    );
  }
}

/// A convenience row of all four social sign-in buttons used in the auth flow.
///
/// Usage:
/// ```dart
/// AppSocialSignInRow(onSocialTap: (provider) => print(provider))
/// ```
class AppSocialSignInRow extends StatelessWidget {
  /// Called with `'google'`, `'facebook'`, `'apple'`, or `'x'`.
  final ValueChanged<String>? onSocialTap;

  const AppSocialSignInRow({super.key, this.onSocialTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppSocialIconButton(
          asset: 'assets/icons/google.png',
          onTap: () => onSocialTap?.call('google'),
        ),
        const SizedBox(width: 19),
        AppSocialIconButton(
          asset: 'assets/icons/facebook.png',
          onTap: () => onSocialTap?.call('facebook'),
        ),
        const SizedBox(width: 19),
        AppSocialIconButton(
          asset: 'assets/icons/apple.png',
          applyWhiteTint: true,
          onTap: () => onSocialTap?.call('apple'),
        ),
        const SizedBox(width: 19),
        AppSocialIconButton(
          asset: 'assets/icons/x.png',
          applyWhiteTint: true,
          onTap: () => onSocialTap?.call('x'),
        ),
      ],
    );
  }
}
