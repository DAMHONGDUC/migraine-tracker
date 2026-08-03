import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/intensity_severity_label.dart';
import 'intensity_disc.dart';

/// First tap: pain intensity 1–10. Buttons are large enough to hit with a
/// shaking hand and tinted by severity so the scale reads at a glance.
/// Selecting advances the flow immediately — no confirm step, this is the
/// fastest way into the flow, mid-attack.
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
        for (int i = startIndex; i <= endIndex; i++) ...[
          _IntensityCircle(value: i, onTap: () => onSelected(i)),
          if (i < endIndex) SdHorizontalSpacingV2(width: SdSpacingConstant.w16),
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
          padding: EdgeInsets.symmetric(
            horizontal: SdContentPaddingV2.horizontal,
            vertical: SdSpacingConstant.h24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _builRowItems(startIndex: 1, endIndex: 3, onSelected: onSelected),
              SdVerticalSpacingV2(height: SdSpacingConstant.h16),
              _builRowItems(startIndex: 4, endIndex: 6, onSelected: onSelected),
              SdVerticalSpacingV2(height: SdSpacingConstant.h16),
              _builRowItems(startIndex: 7, endIndex: 8, onSelected: onSelected),
              SdVerticalSpacingV2(height: SdSpacingConstant.h16),
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
    final l10n = context.l10n;

    // The circle only shows a number; severity is colour-only. Give
    // VoiceOver the full meaning and hide the bare "$value" text.
    return Semantics(
      button: true,
      label: l10n.a11yIntensityButton(value, value.severityLabel(l10n)),
      excludeSemantics: true,
      child: SdPressableScaleV2(
        onTap: onTap,
        child: IntensityDisc(value: value, size: SdSpacingConstant.r88),
      ),
    );
  }
}
