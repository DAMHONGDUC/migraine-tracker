import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

class VerticalSpacing extends StatelessWidget {
  const VerticalSpacing({super.key, this.height, this.xRatio = 1.0});

  final double? height;
  final double xRatio;

  @override
  Widget build(BuildContext context) {
    final value = (height ?? AppSpacingConstant.h12) * xRatio;

    return SizedBox(height: value);
  }
}
