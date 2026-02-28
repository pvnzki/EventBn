import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS — Single Source of Truth
// ─────────────────────────────────────────────────────────────────────────────
//  Change fonts, colours, radii, etc. here ONCE and every screen picks it up.
//  No other file should contain hard-coded colour hex values or font names.
// ─────────────────────────────────────────────────────────────────────────────

// ─── FONT ────────────────────────────────────────────────────────────────────
/// The app-wide font family.  Swap this one string to rebrand the typography.
const String kFontFamily = 'Satoshi';

/// Legacy alias — older files reference [appFontFamily] via app_colors.dart.
const String appFontFamily = kFontFamily;

// ─── COLOUR PALETTE ──────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // ── Brand / Accent ──────────────────────────────────────────────────────
  /// Primary accent used for prices, highlights, active indicators (green).
  static const Color primary = Color(0xFF01DB5F);

  // ── Dark-mode backgrounds ───────────────────────────────────────────────
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF181818);

  /// Slightly lighter card / chip / input fill colour in dark mode.
  static const Color bg01 = Color(0xFF1C1C1C);

  /// Card colour for dark theme (used by Material CardTheme).
  static const Color cardDark = Color(0xFF151515);

  /// Scaffold background for dark theme.
  static const Color scaffoldDark = Color(0xFF121212);

  /// Very dark surface (app bar, etc.) in dark theme.
  static const Color surfaceDark = Color(0xFF0A0A0A);

  // ── Light-mode backgrounds ──────────────────────────────────────────────
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  // ── Borders / Dividers ──────────────────────────────────────────────────
  static const Color divider = Color(0xFF2A2A2A);
  static const Color borderDark = Color(0xFF2A2A2A);

  // ── Text & Icon colours ─────────────────────────────────────────────────
  static const Color white = Color(0xFFFCFCFD);
  static const Color grey = Color(0xFF928C97);
  static const Color grey200 = Color(0xFFBABCC0);
  static const Color grey300 = Color(0xFFA3A7AC);
  static const Color dark = Color(0xFF070B0F);

  // Light-mode text
  static const Color textPrimaryLight = Color(0xFF1F2937);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);

  // Dark-mode text
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFE0E0E0);
  static const Color textTertiaryDark = Color(0xFFB0B0B0);

  // ── Disabled / Input ────────────────────────────────────────────────────
  static const Color inputDisabled = Color(0xFF252525);

  // ── Material colorScheme.primary (button colours) ───────────────────────
  /// In light mode buttons are black-on-white; in dark mode white-on-black.
  static const Color materialPrimaryLight = Color(0xFF000000);
  static const Color materialSecondaryLight = Color(0xFF1A1A1A);
  static const Color materialPrimaryDark = Color(0xFFFFFFFF);
  static const Color materialSecondaryDark = Color(0xFFE5E5E5);

  // ── Semantic ────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color dangerBorder = Color(0xFFC91330);
  static const Color dangerText = Color(0xFFEF5069);
}

// ─── RADII ───────────────────────────────────────────────────────────────────
class AppRadius {
  AppRadius._();

  static const double card = 12.0;
  static const double chip = 20.0;
  static const double button = 8.0;
  static const double input = 8.0;
  static const double cardLg = 16.0;
}
