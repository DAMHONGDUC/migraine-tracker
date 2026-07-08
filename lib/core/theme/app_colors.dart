import 'dart:ui';

/// Photophobia-friendly palette. Hard rule: no pure white anywhere;
/// the brightest surface allowed is the #1C1C1E family.
abstract final class AppColors {
  /// Scaffold background — near black.
  static const Color background = Color(0xFF0E0E10);

  /// Default surface (cards, sheets).
  static const Color surface = Color(0xFF1C1C1E);

  /// Elevated surface (dialogs, raised cards).
  static const Color surfaceElevated = Color(0xFF2C2C2E);

  /// Muted lavender — calm, low-glare accent.
  static const Color primary = Color(0xFFA594F9);
  static const Color onPrimary = Color(0xFF1C1C1E);

  /// Soft teal secondary accent.
  static const Color secondary = Color(0xFF7FB8B0);

  /// Desaturated red for errors — no harsh alarm tones.
  static const Color error = Color(0xFFE5766E);

  /// Off-white text; never pure white.
  static const Color textPrimary = Color(0xFFE4E2E8);
  static const Color textSecondary = Color(0xFF9E9CA6);
}
