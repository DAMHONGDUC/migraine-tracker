import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/log_flow_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/head_region_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/enums/head_region.dart';

/// The areas of one view as named tiles, three to a row — the second way to answer the question the head above it asks.
class HeadRegionGrid extends StatelessWidget {
  const HeadRegionGrid({
    required this.view,
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final HeadView view;
  final List<HeadRegion> selected;
  final ValueChanged<HeadRegion> onToggle;

  /// The shortest a tile may be: two lines of label.
  static double get _tileHeight => SdSpacingConstant.h38;

  /// And the tallest.
  static double get _tileHeightMax => SdSpacingConstant.h56;

  /// Rows in the roomiest view — the front's eleven areas.
  static int get _rows => HeadView.values
      .map(
        (HeadView view) =>
            (HeadRegion.of(view).length / LogFlowConstant.locationOptionsPerRow)
                .ceil(),
      )
      .reduce(math.max);

  /// The least height the grid takes, whichever view is showing.
  static double get reservedHeight =>
      _rows * _tileHeight + (_rows - 1) * SdSpacingConstant.h6;

  /// The most it can usefully take, past which the tiles stop growing.
  static double get maxHeight =>
      _rows * _tileHeightMax + (_rows - 1) * SdSpacingConstant.h6;

  @override
  Widget build(BuildContext context) {
    final List<HeadRegion> regions = HeadRegion.of(view);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double spacing = SdSpacingConstant.h6;
        // Whatever height it is handed goes into the tiles, never a gap under them.
        final double byHeight =
            (constraints.maxHeight - (_rows - 1) * spacing) / _rows;

        return GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: LogFlowConstant.locationOptionsPerRow,
            mainAxisSpacing: spacing,
            crossAxisSpacing: SdSpacingConstant.w8,
            // A row height, not an aspect ratio: the tile is one label, so its height has nothing to do with the screen's width.
            mainAxisExtent: byHeight.clamp(_tileHeight, _tileHeightMax),
          ),
          itemCount: regions.length,
          itemBuilder: (BuildContext context, int index) => _RegionTile(
            region: regions[index],
            selected: selected.contains(regions[index]),
            onTap: () => onToggle(regions[index]),
          ),
        );
      },
    );
  }
}

class _RegionTile extends StatelessWidget {
  const _RegionTile({
    required this.region,
    required this.selected,
    required this.onTap,
  });

  final HeadRegion region;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Color color = selected ? AppColors.primary : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: region.label(l10n),
      excludeSemantics: true,
      child: SdPressableScaleV2(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: SdSpacingConstant.w8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(SdSpacingConstant.r12),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            region.label(l10n),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.labelSmall.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}
