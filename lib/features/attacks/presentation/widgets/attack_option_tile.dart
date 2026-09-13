import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';

/// One option in a sheet answered with a single tap — the duration presets and the start-time presets draw the same tile.
///
/// It was `_DurationSheet`'s private tile; the start sheet needs the identical
/// box, and two copies of a 60-line decoration is how two sheets on the same
/// screen come to look like two different controls.
class AttackOptionTile extends StatelessWidget {
  const AttackOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.detail,
    this.enabled = true,
    super.key,
  });

  /// One owner for how tall an option is, used by a grid's `mainAxisExtent` and by the full-width tile above it.
  static double get height => SdSpacingConstant.h64;

  final String label;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;

  /// A preset that would produce an impossible answer — a start after the end — is shown and refused, never hidden: a grid that loses cells reads as a bug.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color color = switch ((enabled, selected)) {
      (false, _) => AppColors.textSecondary.withValues(alpha: 0.4),
      (true, true) => AppColors.primary,
      (true, false) => AppColors.textPrimary,
    };

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: detail == null ? label : '$label, $detail',
      excludeSemantics: true,
      // IgnorePointer rather than a null callback: SdPressableScaleV2 takes a required one, and a no-op still plays the press animation — which reads as a tap that worked.
      child: IgnorePointer(
        ignoring: !enabled,
        child: SdPressableScaleV2(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(horizontal: SdSpacingConstant.w16),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.14)
                  // A step above the sheet, or the tile disappears into it.
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.titleSmall.copyWith(color: color),
                  ),
                ),
                if (detail != null) ...<Widget>[
                  SizedBox(width: SdSpacingConstant.w8),
                  Text(detail!, style: AppTextStyle.bodyMedium.secondary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
