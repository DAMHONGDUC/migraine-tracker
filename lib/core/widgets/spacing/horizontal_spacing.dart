import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HorizontalSpacing extends StatelessWidget {
  const HorizontalSpacing({super.key, this.width});

  final double? width;

  @override
  Widget build(BuildContext context) {
    final value = width ?? 12.w;

    return SizedBox(width: value);
  }
}
