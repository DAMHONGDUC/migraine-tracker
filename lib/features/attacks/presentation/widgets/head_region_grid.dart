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

/// The areas of one view as named tiles, three to a row — the second way to
/// answer the question the head above it asks.
///
/// It exists because the diagram alone makes the user guess: the bands carry
/// no labels, so "temple" and "eye" are told apart by where a finger lands
/// rather than by a word, and the smallest areas are the hardest to hit
/// exactly. Every area has a full-width target down here, named outright.
/// **Both write the same list** — this is a second door to one answer, not a
/// second answer, so a tile and its band toggle together in either
/// direction.
///
/// Shows only [view]'s own areas, because that is what the head above is
/// showing; turning the head swaps the tiles with it — but never resizes
/// the grid, see [reservedHeight].
///
/// Shrink-wraps and never scrolls itself: whatever holds it owns the
/// scrolling, and the log step must fit on one screen with none.
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

  /// And the tallest. Slack is worth spending on a tap target up to a point,
  /// past which a one-word tile is a slab with a word lost in the middle of
  /// it — better given back to the whitespace around the step.
  static double get _tileHeightMax => SdSpacingConstant.h56;

  /// Rows in the roomiest view — the front's eleven areas.
  static int get _rows => HeadView.values
      .map(
        (HeadView view) =>
            (HeadRegion.of(view).length / LogFlowConstant.locationOptionsPerRow)
                .ceil(),
      )
      .reduce(math.max);

  /// The **least** height the grid takes, whichever view is showing.
  ///
  /// Fixed, and sized for the roomiest view, **because the head above it
  /// must not move when the head is turned**: the back has four tiles to the
  /// front's eleven, and a grid that shrank to its own content would hand the
  /// difference to the diagram's `Expanded` and redraw the head at another
  /// size in another place. The empty rows on the back view are the price,
  /// and they are cheaper than a head that jumps.
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
        // Whatever height it is handed goes into the tiles, never into a gap
        // under them: the head is sized from its width now, so what it does
        // not use is worth more as a tap target than as air. Bounded both
        // ways — [_tileHeight] is two lines of label and what
        // [reservedHeight] promised the head, [_tileHeightMax] is where a
        // tile stops being a button and starts being a slab.
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
            // A row height, not an aspect ratio: the tile is one label, so
            // how tall it is has nothing to do with how wide the screen made
            // it. Every cell is the same box, which is what keeps a selected
            // tile — 2px of border against everyone else's 1 — the size of
            // its neighbour.
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
