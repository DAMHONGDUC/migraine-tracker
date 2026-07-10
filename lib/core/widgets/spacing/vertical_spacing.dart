import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VerticalSpacing extends StatelessWidget {
  const VerticalSpacing({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    final value = height ?? 12.h;

    return SizedBox(height: value);
  }
}
