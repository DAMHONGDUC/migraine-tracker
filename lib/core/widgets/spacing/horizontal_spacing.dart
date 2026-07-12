import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

class HorizontalSpacing extends StatelessWidget {
  const HorizontalSpacing({super.key, this.width});

  final double? width;

  @override
  Widget build(BuildContext context) {
    final value = width ?? AppSpacingConstant.w12;

    return SizedBox(width: value);
  }
}
