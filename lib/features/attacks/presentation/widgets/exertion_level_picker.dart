import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/log_flow_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/exertion_level_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/enums/exertion_level.dart';

/// The exertion-level tiles, two to a row.
class ExertionLevelPicker extends StatelessWidget {
  const ExertionLevelPicker({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final ExertionLevel? selected;
  final ValueChanged<ExertionLevel> onSelected;

  /// How many tiles share a row.

  @override
  Widget build(BuildContext context) {
    final List<ExertionLevel> levels = ExertionLevel.values;

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      // Whatever holds this owns the scrolling — the log step needs none, the sheet has its own.
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: LogFlowConstant.optionsPerRow,
        mainAxisSpacing: SdSpacingConstant.h8,
        crossAxisSpacing: SdSpacingConstant.w8,
        // A fixed row height, not an aspect ratio: the tile is one line beside an icon, so its height has nothing to do with the screen's width.
        mainAxisExtent: SdSpacingConstant.h64,
      ),
      itemCount: levels.length,
      itemBuilder: (BuildContext context, int index) => _ExertionTile(
        level: levels[index],
        selected: selected == levels[index],
        onTap: () => onSelected(levels[index]),
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
    ExertionLevel.none: AppIconConstant.exertionNone,
    ExertionLevel.light: AppIconConstant.steps,
    ExertionLevel.moderate: AppIconConstant.exertionModerate,
    ExertionLevel.severe: AppIconConstant.exertionSevere,
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
          padding: EdgeInsets.symmetric(horizontal: SdSpacingConstant.w16),
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
          child: Row(
            children: <Widget>[
              SdIconV2(
                icon: _icons[level]!,
                color: color,
                size: AppIconSize.medium,
              ),
              SizedBox(width: SdSpacingConstant.w12),
              Expanded(
                child: Text(
                  level.label(l10n),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.titleSmall.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
