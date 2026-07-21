import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

class FittedText extends StatelessWidget {
  const FittedText(
    this.label, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.center,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.stripNewlines = false,
    this.minFontSize,
  });

  final String label;
  final TextStyle style;
  final TextAlign textAlign;
  final int maxLines;
  final TextOverflow overflow;
  final bool stripNewlines;
  final double? minFontSize;

  String get _processedLabel =>
      stripNewlines ? label.replaceAll('\n', ' ') : label;

  @override
  Widget build(BuildContext context) {
    const double step = 0.1;
    final double min = (minFontSize ?? AppSpacingConstant.sp8).roundToDouble();
    final double maxFs = (style.fontSize ?? AppSpacingConstant.sp14)
        .roundToDouble();

    return AutoSizeText(
      _processedLabel,
      style: style.copyWith(fontSize: maxFs),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      minFontSize: min,
      stepGranularity: step,
    );
  }
}
