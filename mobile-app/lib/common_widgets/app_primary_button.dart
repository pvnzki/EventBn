import 'package:flutter/material.dart';
import 'app_colors.dart';

/// A rounded primary action button matching the Figma design system.
///
/// When [enabled] is `false` (or [onPressed] is null) the button renders in its
/// disabled / inactive style (dark grey background, muted text).
///
/// Usage:
/// ```dart
/// AppPrimaryButton(
///   label: 'Continue',
///   onPressed: _hasInput ? _handleSignIn : null,
///   isLoading: _isLoading,
/// )
/// ```
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 48,
  });

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: _enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _enabled ? AppColors.primary : AppColors.inputDisabled,
          foregroundColor: _enabled ? AppColors.dark : AppColors.grey200,
          disabledBackgroundColor: AppColors.inputDisabled,
          disabledForegroundColor: AppColors.grey200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontFamily: appFontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  height: 1.2,
                ),
              ),
      ),
    );
  }
}
