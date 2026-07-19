import 'package:flutter/material.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';
import 'package:migraine_tracker/core/widgets/spacing/horizontal_spacing.dart';
import 'package:migraine_tracker/core/widgets/spacing/vertical_spacing.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/intensity_severity_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pressable_scale.dart';

/// First tap: pain intensity 1–10. Buttons are large enough to hit with a
/// shaking hand and tinted by severity so the scale reads at a glance.
/// Selecting advances the flow immediately.
class IntensityStep extends StatelessWidget {
  const IntensityStep({required this.onSelected, super.key});

  final ValueChanged<int> onSelected;

  Widget _builRowItems({
    required void Function(int) onSelected,
    required int startIndex,
    required int endIndex,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = startIndex; i <= endIndex; i++) ...[
          _IntensityCircle(value: i, onTap: () => onSelected(i)),
          if (i < endIndex) HorizontalSpacing(width: AppSpacingConstant.w16),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        builder: (context, t, child) => Opacity(opacity: t, child: child),
        // Scrollable so the four rows never overflow on short screens.
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacingConstant.w24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _builRowItems(startIndex: 1, endIndex: 3, onSelected: onSelected),
              VerticalSpacing(height: AppSpacingConstant.h16),
              _builRowItems(startIndex: 4, endIndex: 6, onSelected: onSelected),
              VerticalSpacing(height: AppSpacingConstant.h16),
              _builRowItems(startIndex: 7, endIndex: 8, onSelected: onSelected),
              VerticalSpacing(height: AppSpacingConstant.h16),
              _builRowItems(
                startIndex: 9,
                endIndex: 10,
                onSelected: onSelected,
              ),
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
    final l10n = context.l10n;
    // The circle only shows a number; severity is colour-only. Give
    // VoiceOver the full meaning and hide the bare "$value" text.
    return Semantics(
      button: true,
      label: l10n.a11yIntensityButton(value, value.severityLabel(l10n)),
      excludeSemantics: true,
      child: PressableScale(
        onTap: onTap,
        child: Container(
        width: AppSpacingConstant.r88,
        height: AppSpacingConstant.r88,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Severity lives in the fill/border; the number wears the text
          // token so it stays readable at every step of the ramp.
          color: color.withValues(alpha: 0.45),
          border: Border.all(color: color, width: 1.5),
        ),
        child: FittedBox(
          child: Text(
            '$value',
            style: context.textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ),
      ),
    );
  }
}
