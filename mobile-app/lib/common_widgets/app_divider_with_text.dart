import 'package:flutter/material.dart';
import 'app_colors.dart';

/// A thin horizontal line with a centred label, e.g. "or sign in with".
///
/// Usage:
/// ```dart
/// AppDividerWithText(text: 'or sign in with')
/// ```
class AppDividerWithText extends StatelessWidget {
  final String text;

  const AppDividerWithText({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: appFontFamily,
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: AppColors.grey200,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: AppColors.divider)),
      ],
    );
  }
}
