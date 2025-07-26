import 'package:flutter/material.dart';

class ThemeUtils {
  /// Returns black in light mode, white in dark mode
  static Color getPrimaryColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : Colors.black;
  }

  /// Returns dark grey in light mode, light grey in dark mode
  static Color getSecondaryColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFFE5E5E5) : const Color(0xFF1A1A1A);
  }

  /// Returns primary color with specified opacity
  static Color getPrimaryColorWithOpacity(
      BuildContext context, double opacity) {
    return getPrimaryColor(context)
        .withValues(alpha: opacity); // Fixed deprecated method
  }

  /// Returns primary color with specified alpha
  static Color getPrimaryColorWithAlpha(BuildContext context, double alpha) {
    return getPrimaryColor(context).withValues(alpha: alpha);
  }
}
