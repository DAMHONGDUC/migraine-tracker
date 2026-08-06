import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/exertion_level_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/enums/exertion_level.dart';

/// The three exertion-level tiles, one row. Optional field: tapping the
/// already-selected level clears it back to "not answered."
class ExertionLevelPicker extends StatelessWidget {
  const ExertionLevelPicker({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final ExertionLevel? selected;
  final ValueChanged<ExertionLevel?> onSelected;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final ExertionLevel level in ExertionLevel.values) ...[
            if (level != ExertionLevel.values.first)
              SizedBox(width: SdSpacingConstant.w8),
            Expanded(
              child: _ExertionTile(
                level: level,
                selected: selected == level,
                onTap: () => onSelected(selected == level ? null : level),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExertionTile extends StatelessWidget {
  const _ExertionTile({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final ExertionLevel level;
  final bool selected;
  final VoidCallback onTap;

  static const Map<ExertionLevel, IconData> _icons = <ExertionLevel, IconData>{
    ExertionLevel.light: Icons.directions_walk,
    ExertionLevel.moderate: Icons.directions_run,
    ExertionLevel.severe: Icons.fitness_center,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final Color color = selected ? AppColors.primary : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: level.label(l10n),
      excludeSemantics: true,
      child: SdPressableScaleV2(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.all(SdSpacingConstant.w4),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.14)
                // One step above card colour, or it vanishes into the sheet below.
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(SdSpacingConstant.r16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SdIconV2(icon: _icons[level]!, color: color, size: SdSpacingConstant.r24),
              SizedBox(height: SdSpacingConstant.h4),
              Text(
                level.label(l10n),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.labelTiny.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
