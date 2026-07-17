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

  /// Chart series color — one step darker than [primary] so it sits inside
  /// the dark-mode lightness band (validated: contrast ≥3:1 on [surface]).
  static const Color chartSeries = Color(0xFF9182EC);

  /// Recessive grid lines for charts.
  static const Color chartGrid = Color(0xFF2C2C2E);

  /// Off-white text; never pure white.
  static const Color textPrimary = Color(0xFFE4E2E8);
  static const Color textSecondary = Color(0xFF9E9CA6);

  /// Modal barrier behind dialogs/sheets.
  static const Color barrier = Color(0x99000000);

  static const Color transparent = Color(0x00000000);

  /// Severity tint for a 1–10 pain intensity, in four bands.
  ///
  /// Intensity is ORDINAL (magnitude), so this is a single-hue ramp that
  /// gets brighter as the pain gets worse — not a green→amber→orange→red
  /// rainbow. The rainbow encoded severity in hue alone, which made 7–8 and
  /// 9–10 nearly identical (ΔE 5 for normal vision, 1.7 for deutan). Here
  /// each step is a measured lightness apart (ΔL ≥ 0.06), so the order
  /// survives every kind of colour blindness.
  ///
  /// Validated as an ordinal ramp against the dark surface: lightness
  /// monotone, adjacent ΔL ≥ 0.06, dim-end contrast 2.1:1, hue spread 6°.
  /// Use for fills/borders only — numbers wear [textPrimary].
  static Color intensity(int value) {
    if (value <= 3) return const Color(0xFF7A3B44); // mild
    if (value <= 6) return const Color(0xFFA84A54); // moderate
    if (value <= 8) return const Color(0xFFD05A62); // severe
    return const Color(0xFFF26D77); // extreme
  }
}
