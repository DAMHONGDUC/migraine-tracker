import 'package:system_design/index.dart';

/// The size ladder every icon in the app is drawn at, named by the job the glyph does rather than by its number.
final class AppIconSize {
  /// A glyph reading as punctuation inside a line of text: the pin before a place name, the lock before a privacy note. Never the subject.
  static double get inline => SdSpacingConstant.r16;

  /// A chevron or a disclosure arrow — it says "this opens" and nothing else, so it stays a step below the glyph naming the row.
  static double get affordance => SdSpacingConstant.r20;

  /// The glyph that says what a row, a settings tile or a compact reading IS. The default: reach for this one unless another role fits better.
  static double get row => SdSpacingConstant.r24;

  /// The glyph on a tile whose whole content is that glyph and one word — a dashboard shortcut, the log button.
  static double get tile => SdSpacingConstant.r28;

  /// An empty state, a permission sheet, a full-stop moment.
  static double get hero => SdSpacingConstant.r44;

  /// The one-per-screen illustration: onboarding, the saved-attack tick.
  static double get display => SdSpacingConstant.r64;
}
