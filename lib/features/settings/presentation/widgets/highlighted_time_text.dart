import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_style.dart';

/// Renders [full] as one line, gently highlighting the [highlight] substring
/// (a ticking countdown/time) in [color] + semibold with tabular figures so it
/// stands out calmly and doesn't jitter as digits change. Falls back to plain
/// text if the substring isn't found.
class HighlightedTimeText extends StatelessWidget {
  const HighlightedTimeText({
    required this.full,
    required this.highlight,
    required this.color,
    this.baseStyle,
    super.key,
  });

  final String full;
  final String highlight;
  final Color color;

  /// Style for the non-highlighted text; defaults to muted body-small.
  final TextStyle? baseStyle;

  @override
  Widget build(BuildContext context) {
    final base = baseStyle ?? AppTextStyle.bodySmall.secondary;
    final accent = base.w600.copyWith(
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final index = full.indexOf(highlight);
    if (index < 0) {
      return Text(
        full,
        style: base,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: full.substring(0, index), style: base),
          TextSpan(text: highlight, style: accent),
          TextSpan(text: full.substring(index + highlight.length), style: base),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
