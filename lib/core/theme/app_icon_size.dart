import 'package:system_design/index.dart';

/// The size ladder every icon in the app is drawn at.
///
/// Named by step, not by job. The role names ("row", "tile", "hero") each
/// claimed one number and let it sit anywhere on the scale, so the ladder ran
/// 16-20-24-28 four apart and then jumped to 44 and 64. A size is what these
/// are; the comment on each step says where it is used.
///
/// Every step above [medium] is a multiple of 8, so a glyph lands on the same
/// grid the spacing does.
final class AppIconSize {
  /// 16 — a glyph reading as punctuation inside a line of text: the pin before a place name, the lock before a privacy note. Never the subject.
  static double get xSmall => SdSpacingConstant.r16;

  /// 20 — a chevron or a disclosure arrow. It says "this opens" and nothing else, so it stays a step below the glyph naming the row.
  static double get small => SdSpacingConstant.r20;

  /// 24 — the glyph that says what a row, a settings tile or a compact reading IS. The default: reach for this one unless another step fits better.
  static double get medium => SdSpacingConstant.r24;

  /// 32 — the glyph on a tile whose whole content is that glyph and one word: a dashboard shortcut, the log button.
  static double get large => SdSpacingConstant.r32;

  /// 48 — an empty state, a permission sheet, a full-stop moment.
  static double get xLarge => SdSpacingConstant.r48;

  /// 64 — the one-per-screen illustration: onboarding, the saved-attack tick.
  static double get xxLarge => SdSpacingConstant.r64;
}
