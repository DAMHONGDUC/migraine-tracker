import 'dart:ui';

/// Photophobia-friendly palette. Hard rule: no pure white anywhere;
/// the brightest surface allowed is the #1C1C1E family.
final class AppColors {
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

  /// Severity tint for a 1–10 pain intensity, in four bands: the familiar
  /// green → yellow → orange → red scale.
  ///
  /// Every step is measured, not eyeballed. Each adjacent pair clears the
  /// normal-vision floor (ΔE ≥ 15) AND the colour-blind target (ΔE ≥ 8)
  /// against the dark surface:
  ///   green↔yellow  ΔE 18.0 normal / 14.8 CVD
  ///   yellow↔orange ΔE 15.4 normal / 10.1 CVD
  ///   orange↔red    ΔE 15.7 normal / 13.5 CVD
  ///
  /// Squeezing four bands into one hue journey is tight — nudging any step
  /// toward its neighbour collapses that pair (the previous orange/red sat
  /// at ΔE 5.0 normal, 1.7 deutan: the same colour to most eyes). Re-measure
  /// before changing any value here.
  ///
  /// Use for fills/borders only — the red is 3.5:1 on [surface], fine for a
  /// mark but below the 4.5:1 text floor, so numbers wear [textPrimary].
  static Color intensity(int value) {
    if (value <= 3) return const Color(0xFF6FA890); // mild — green
    if (value <= 6) return const Color(0xFFD9C24E); // moderate — yellow
    if (value <= 8) return const Color(0xFFE8823A); // severe — orange
    return const Color(0xFFCF3B34); // extreme — red
  }
}
