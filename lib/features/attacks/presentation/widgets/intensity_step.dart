import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pressable_scale.dart';

/// First tap: pain intensity 1–10. Buttons are large enough to hit with a
/// shaking hand and tinted by severity so the scale reads at a glance.
/// Selecting advances the flow immediately.
class IntensityStep extends StatelessWidget {
  const IntensityStep({required this.onSelected, super.key});

  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        builder: (context, t, child) =>
            Opacity(opacity: t, child: child),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Wrap(
            spacing: 16.w,
            runSpacing: 16.h,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 1; i <= 10; i++)
                _IntensityCircle(value: i, onTap: () => onSelected(i)),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntensityCircle extends StatelessWidget {
  const _IntensityCircle({required this.value, required this.onTap});

  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.intensity(value);
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 72.r,
        height: 72.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.20),
          border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
        ),
        child: FittedBox(
          child: Text(
            '$value',
            style: context.textTheme.headlineSmall?.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}
