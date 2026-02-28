import 'package:flutter/material.dart';
import 'app_colors.dart';

/// A dark-themed text field matching the Figma design system.
///
/// Usage:
/// ```dart
/// AppDarkTextField(
///   controller: _emailController,
///   placeholder: 'Enter your email',
///   hasError: false,
/// )
/// ```
class AppDarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final bool hasError;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const AppDarkTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.hasError = false,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: hasError
            ? Border.all(color: AppColors.dangerBorder, width: 1)
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              onChanged: onChanged,
              cursorColor: AppColors.primary,
              style: const TextStyle(
                fontFamily: appFontFamily,
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 1.2,
                color: AppColors.white,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: placeholder,
                hintStyle: const TextStyle(
                  fontFamily: appFontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  height: 1.2,
                  color: AppColors.grey200,
                ),
                // Fill the full 48px height so the tap target is generous.
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                isDense: false,
              ),
            ),
          ),
          if (suffix != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: suffix!,
            ),
          ],
        ],
      ),
    );
  }
}
