import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/exertion_level_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/enums/exertion_level.dart';

/// The exertion-level tiles, two to a row.
///
/// Same 2-up grid and the same tile shape as `MedicationGrid`, the step next
/// door: four across one row left every label a cramped two-line scrap, and
/// the two adjacent steps read as two different components.
///
/// A tap always selects — there is no clearing back to "not answered",
/// because [ExertionLevel.none] is the answer for "I wasn't exerting
/// myself". [selected] is still nullable so an attack logged before the
/// step existed renders with nothing highlighted.
class ExertionLevelPicker extends StatelessWidget {
  const ExertionLevelPicker({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final ExertionLevel? selected;
  final ValueChanged<ExertionLevel> onSelected;

  /// How many tiles share a row.
  static const int perRow = 2;

  @override
  Widget build(BuildContext context) {
    final List<ExertionLevel> levels = ExertionLevel.values;

    // Rows of Expanded, not a GridView: this sits inside the log step's
    // Column, where a shrink-wrapping scrollable is one more viewport to
    // reason about for a fixed four tiles that never scroll.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int start = 0; start < levels.length; start += perRow) ...<Widget>[
          if (start > 0) SizedBox(height: SdSpacingConstant.h8),
          SizedBox(
            // A fixed row height: the tile is one line of text beside an
            // icon, so how tall it is has nothing to do with how wide the
            // screen made it.
            height: SdSpacingConstant.h64,
            child: Row(
              // Stretch, or each tile sizes to its own content and the
              // selected one — 2px of border against everyone else's 1 —
              // comes out taller than the tile beside it.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (
                  int i = start;
                  i < start + perRow && i < levels.length;
                  i++
                ) ...<Widget>[
                  if (i > start) SizedBox(width: SdSpacingConstant.w8),
                  Expanded(
                    child: _ExertionTile(
                      level: levels[i],
                      selected: selected == levels[i],
                      onTap: () => onSelected(levels[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
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
    ExertionLevel.none: Icons.self_improvement,
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
                size: SdSpacingConstant.r24,
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
