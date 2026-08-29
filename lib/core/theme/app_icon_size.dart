import 'package:system_design/index.dart';

/// The size ladder every icon in the app is drawn at, named by the job the
/// glyph does rather than by its number.
///
/// It exists because the app had no ladder: identifying glyphs sat at r16,
/// r18, r20 and r24 depending on which screen wrote them, chevrons sat at
/// r20 in some rows and at `SdIconV2`'s implicit r24 in others, and three
/// sibling picker sheets in the same feature drew the same shape at two
/// different sizes. The result was a screen where the arrow saying "tappable"
/// carried as much weight as the glyph saying *what the row is*.
///
/// The rule the ladder encodes: **a glyph that identifies is always a step
/// above a glyph that only decorates.** Pick the role, never the number, and
/// never a raw `SdSpacingConstant.r*` at an icon call site.
///
/// Lives here rather than in the design system package for the same reason
/// the palette and the type scale do — it is this product's look, and the
/// package must stay droppable into the next one.
final class AppIconSize {
  /// A glyph reading as punctuation inside a line of text: the pin before a
  /// place name, the lock before a privacy note. Never the subject.
  static double get inline => SdSpacingConstant.r16;

  /// A chevron or a disclosure arrow — it says "this opens" and nothing
  /// else, so it stays a step below the glyph naming the row.
  static double get affordance => SdSpacingConstant.r20;

  /// The glyph that says what a row, a settings tile or a compact reading
  /// IS. The default: reach for this one unless another role fits better.
  static double get row => SdSpacingConstant.r24;

  /// The glyph on a tile whose whole content is that glyph and one word — a
  /// dashboard shortcut, the log button. It carries the identity on its own,
  /// so it is drawn to be read at a glance rather than inspected. Check the
  /// box first: `HistoryViewToggle` wants [row] instead, because its 34-tall
  /// thumb leaves a 28 glyph 3pt of air.
  static double get tile => SdSpacingConstant.r28;

  /// An empty state, a permission sheet, a full-stop moment.
  static double get hero => SdSpacingConstant.r44;

  /// The one-per-screen illustration: onboarding, the saved-attack tick.
  static double get display => SdSpacingConstant.r64;
}
