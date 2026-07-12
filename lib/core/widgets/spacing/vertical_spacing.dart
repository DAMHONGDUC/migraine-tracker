import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

class VerticalSpacing extends StatelessWidget {
  const VerticalSpacing({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    final value = height ?? AppSpacingConstant.h12;

    return SizedBox(height: value);
  }
}
