import 'package:flutter/material.dart';
import 'app_colors.dart';

/// A reusable dark-themed screen header with a back arrow and title.
///
/// Matches the Figma "< Title" header pattern used across the sign-up flow.
///
/// Usage:
/// ```dart
/// AppScreenHeader(
///   title: 'Verification',
///   onBack: () => Navigator.of(context).pop(),
/// )
/// ```
class AppScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const AppScreenHeader({
    super.key,
    required this.title,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack ?? () => Navigator.of(context).pop(),
            child: Image.asset(
              'assets/icons/arrow icon.png',
              width: 24,
              height: 24,
              color: AppColors.white,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.chevron_left,
                color: AppColors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: appFontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 16,
              height: 1.2,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
