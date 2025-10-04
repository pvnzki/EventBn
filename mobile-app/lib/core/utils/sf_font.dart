import 'package:flutter/material.dart';

/// Font utility class for San Francisco font styles
class SFFont {
  // Font families - Using SF Pro Display for all text since that's what we have
  static const String display = 'SF Pro Display';
  static const String text = 'SF Pro Display'; // Same as display since we only have SF Pro Display
  
  // Quick access to common text styles with San Francisco fonts
  
  /// Large display text - for app titles, hero sections
  static TextStyle displayLarge({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: display,
      fontSize: fontSize ?? 57,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      letterSpacing: letterSpacing ?? -0.25,
    );
  }
  
  /// Medium display text - for section headers
  static TextStyle displayMedium({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
  }) {
    return TextStyle(
      fontFamily: display,
      fontSize: fontSize ?? 45,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
    );
  }
  
  /// Small display text - for page headers
  static TextStyle displaySmall({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
  }) {
    return TextStyle(
      fontFamily: display,
      fontSize: fontSize ?? 36,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
    );
  }
  
  /// Large headline - for main headers
  static TextStyle headlineLarge({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
  }) {
    return TextStyle(
      fontFamily: display,
      fontSize: fontSize ?? 32,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
    );
  }
  
  /// Medium headline - for sub headers
  static TextStyle headlineMedium({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
  }) {
    return TextStyle(
      fontFamily: display,
      fontSize: fontSize ?? 28,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
    );
  }
  
  /// Small headline - for card headers
  static TextStyle headlineSmall({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
  }) {
    return TextStyle(
      fontFamily: display,
      fontSize: fontSize ?? 24,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
    );
  }
  
  /// Large title - for dialog titles, important labels
  static TextStyle titleLarge({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
  }) {
    return TextStyle(
      fontFamily: display,
      fontSize: fontSize ?? 22,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
    );
  }
  
  /// Medium title - for list item titles
  static TextStyle titleMedium({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: display,
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
      letterSpacing: letterSpacing ?? 0.15,
    );
  }
  
  /// Small title - for small headers
  static TextStyle titleSmall({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: display,
      fontSize: fontSize ?? 14,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
      letterSpacing: letterSpacing ?? 0.1,
    );
  }
  
  /// Large body text - for main content
  static TextStyle bodyLarge({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: text,
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      letterSpacing: letterSpacing ?? 0.5,
    );
  }
  
  /// Medium body text - for secondary content
  static TextStyle bodyMedium({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: text,
      fontSize: fontSize ?? 14,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      letterSpacing: letterSpacing ?? 0.25,
    );
  }
  
  /// Small body text - for captions, footnotes
  static TextStyle bodySmall({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: text,
      fontSize: fontSize ?? 12,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      letterSpacing: letterSpacing ?? 0.4,
    );
  }
  
  /// Large label - for button text
  static TextStyle labelLarge({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: text,
      fontSize: fontSize ?? 14,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color,
      letterSpacing: letterSpacing ?? 0.1,
    );
  }
  
  /// Medium label - for form labels
  static TextStyle labelMedium({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: text,
      fontSize: fontSize ?? 12,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color,
      letterSpacing: letterSpacing ?? 0.5,
    );
  }
  
  /// Small label - for small indicators
  static TextStyle labelSmall({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: text,
      fontSize: fontSize ?? 11,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color,
      letterSpacing: letterSpacing ?? 0.5,
    );
  }
  
  // Custom weight methods for San Francisco
  
  /// San Francisco Ultralight
  static TextStyle ultralight({
    required double fontSize,
    Color? color,
    String? fontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily ?? text,
      fontSize: fontSize,
      fontWeight: FontWeight.w100,
      color: color,
    );
  }
  
  /// San Francisco Thin
  static TextStyle thin({
    required double fontSize,
    Color? color,
    String? fontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily ?? text,
      fontSize: fontSize,
      fontWeight: FontWeight.w200,
      color: color,
    );
  }
  
  /// San Francisco Light
  static TextStyle light({
    required double fontSize,
    Color? color,
    String? fontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily ?? text,
      fontSize: fontSize,
      fontWeight: FontWeight.w300,
      color: color,
    );
  }
  
  /// San Francisco Regular
  static TextStyle regular({
    required double fontSize,
    Color? color,
    String? fontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily ?? text,
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }
  
  /// San Francisco Medium
  static TextStyle medium({
    required double fontSize,
    Color? color,
    String? fontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily ?? text,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }
  
  /// San Francisco Semibold
  static TextStyle semibold({
    required double fontSize,
    Color? color,
    String? fontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily ?? text,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }
  
  /// San Francisco Bold
  static TextStyle bold({
    required double fontSize,
    Color? color,
    String? fontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily ?? text,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }
  
  /// San Francisco Heavy
  static TextStyle heavy({
    required double fontSize,
    Color? color,
    String? fontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily ?? text,
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      color: color,
    );
  }
  
  /// San Francisco Black
  static TextStyle black({
    required double fontSize,
    Color? color,
    String? fontFamily,
  }) {
    return TextStyle(
      fontFamily: fontFamily ?? text,
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      color: color,
    );
  }
}