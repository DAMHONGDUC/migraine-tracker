import 'package:flutter/material.dart';

/// Text that shrinks its own font size to stay within [maxLines] instead of
/// wrapping or overflowing — e.g. the log flow's step questions, which must
/// always read as a single line regardless of locale/string length.
///
/// Unlike a bare [FittedBox], this respects [maxLines] > 1 correctly (a
/// `FittedBox` scales the whole laid-out block, which only reads right for
/// single-line text) by binary-searching the largest scale that still fits,
/// via [TextPainter] — the same measuring approach `auto_size_text`-style
/// packages use, kept in-house since the app avoids new dependencies for
/// something this small.
class FittedText extends StatelessWidget {
  const FittedText(
    this.text, {
    required this.style,
    this.maxLines = 1,
    this.textAlign,
    this.minScale = 0.6,
    super.key,
  });

  final String text;
  final TextStyle style;
  final int maxLines;
  final TextAlign? textAlign;

  /// Floor for the shrink — below this the text just ellipsises instead of
  /// becoming illegibly small.
  final double minScale;

  bool _fits(double scale, double maxWidth, TextDirection direction) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style.copyWith(fontSize: fontSizeOf(scale))),
      maxLines: maxLines,
      textAlign: textAlign ?? TextAlign.start,
      textDirection: direction,
    )..layout(maxWidth: maxWidth);
    return !painter.didExceedMaxLines;
  }

  double fontSizeOf(double scale) => (style.fontSize ?? 14) * scale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final direction = Directionality.of(context);
        var lo = minScale;
        var hi = 1.0;
        // 1.0 already fits: skip the search entirely.
        if (_fits(hi, constraints.maxWidth, direction)) {
          lo = hi;
        } else {
          // Binary search for the largest scale in [minScale, 1.0] that
          // still fits within maxLines — a handful of layout passes, cheap
          // for the short question strings this is used for.
          for (var i = 0; i < 8; i++) {
            final mid = (lo + hi) / 2;
            if (_fits(mid, constraints.maxWidth, direction)) {
              lo = mid;
            } else {
              hi = mid;
            }
          }
        }
        return Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: style.copyWith(fontSize: fontSizeOf(lo)),
        );
      },
    );
  }
}
