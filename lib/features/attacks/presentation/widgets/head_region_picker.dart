import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/head_region_label.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/enums/head_region.dart';
import 'head_diagram.dart';
import 'head_region_geometry.dart';
import 'head_region_grid.dart';

/// Picking where it hurts: a Front/Back tab pair, the head itself, and the
/// same areas as named tiles under it.
///
/// **The head and the tiles are one answer with two doors.** Both call
/// [_toggle], so a band and its tile light up together whichever was
/// touched; the tiles are there because the bands carry no labels and the
/// small ones are hard to hit, not because they record anything the head
/// cannot.
///
/// Shared by the log flow's second tap ([LocationStep]) and the attack
/// detail's edit sheet, so correcting a location afterwards looks exactly
/// like picking it in the first place.
///
/// **The head never moves, and it gets every point nothing else needs.** It
/// is the one thing on this screen the user is aiming at, and it sits in an
/// `Expanded`, so anything under it that changes size hands the difference
/// straight to the diagram and redraws it somewhere else — which is why
/// [HeadRegionGrid] reserves a constant height for the roomiest view. It is
/// also why there is no line spelling the picked areas out under the grid
/// any more: the tiles name every one of them and light the picked ones up,
/// so that line cost the head 40pt to repeat what was already on screen.
///
/// **The tab is view state, not an answer** — it lives here rather than in
/// `LogController`, because turning the head around records nothing. Only
/// [onChanged] does. It opens on whichever side already holds more of
/// [selected], so editing a back-of-head attack does not open on a blank
/// face.
class HeadRegionPicker extends StatefulWidget {
  const HeadRegionPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<HeadRegion> selected;
  final ValueChanged<List<HeadRegion>> onChanged;

  @override
  State<HeadRegionPicker> createState() => _HeadRegionPickerState();
}

class _HeadRegionPickerState extends State<HeadRegionPicker> {
  late HeadView _view = HeadRegion.primaryView(widget.selected);

  /// How far the head sits in from everything around it — the screen edge
  /// either side, the tabs above, the tiles below. Owner's number, and the
  /// same on both axes on purpose: the head is a round thing in a column of
  /// rectangles, and an even ring of air is what stops it reading as wedged
  /// between them. Still wider than the step's own 16pt gutter, which the
  /// tabs and the tiles keep, because those two want the width and the head
  /// does not — but only just: this number is also what caps the head's
  /// size, since the head is sized from the width inside it.
  static double get _headInset => SdSpacingConstant.w30;

  /// Toggles one area, keeping the result in [HeadRegion] order so two
  /// attacks naming the same areas are the same list — the sync codec
  /// compares payloads, and an order that followed the taps would make an
  /// unchanged attack look edited.
  void _toggle(HeadRegion region) {
    final Set<HeadRegion> next = widget.selected.toSet();

    if (!next.remove(region)) next.add(region);

    widget.onChanged(<HeadRegion>[
      for (final HeadRegion candidate in HeadRegion.values)
        if (next.contains(candidate)) candidate,
    ]);
  }

  int _countOn(HeadView view) =>
      widget.selected.where((HeadRegion r) => r.showsOn(view)).length;

  /// Null rather than 0: a bare tab reads as "nothing here yet", where a
  /// zero reads as a number the user has to check.
  int? _badgeFor(HeadView view) {
    final int count = _countOn(view);

    return count == 0 ? null : count;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SdContentPaddingV2.horizontal,
          ),
          child: SdSegmentedTabsV2(
            segments: <SdSegmentV2>[
              SdSegmentV2(
                label: l10n.logLocationViewFront,
                count: _badgeFor(HeadView.front),
              ),
              SdSegmentV2(
                label: l10n.logLocationViewBack,
                count: _badgeFor(HeadView.back),
              ),
            ],
            selectedIndex: HeadView.values.indexOf(_view),
            onSelected: (int index) =>
                setState(() => _view = HeadView.values[index]),
          ),
        ),
        SdVerticalSpacingV2(height: _headInset),
        // The head is sized from its WIDTH, not from what is left over
        // (owner's rule); the `min` below only guards a short column. What it
        // does not use goes to the tiles, and the rest is margin either side.
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double gap = _headInset;
              final double byWidth =
                  (constraints.maxWidth - _headInset * 2) /
                  HeadRegionGeometry.aspectRatio;
              final double head = math.min(
                byWidth,
                constraints.maxHeight - gap - HeadRegionGrid.reservedHeight,
              );
              final double grid = (constraints.maxHeight - head - gap).clamp(
                HeadRegionGrid.reservedHeight,
                HeadRegionGrid.maxHeight,
              );

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: head,
                    child: Semantics(
                      label: widget.selected.isEmpty
                          ? l10n.logLocationNone
                          : widget.selected.label(l10n),
                      excludeSemantics: true,
                      child: _SideLabelled(
                        inset: _headInset,
                        child: HeadDiagram(
                          selected: widget.selected,
                          view: _view,
                          onRegionTapped: _toggle,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: gap),
                  SizedBox(
                    height: grid,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: SdContentPaddingV2.horizontal,
                      ),
                      child: HeadRegionGrid(
                        view: _view,
                        selected: widget.selected,
                        onToggle: _toggle,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The L and R that flank the head. They are the whole reason the front view
/// is drawn mirrored: without them nobody can tell whose left is meant, and
/// with them the answer has to be "yours" on both views (see [HeadRegion]).
///
/// They live in the [inset] gutter, which costs the head nothing — the head
/// is sized from the width inside that gutter either way. Back when the head
/// took the whole width they had to sit over the drawing's corners instead;
/// there is no reason to keep them there now.
///
/// [child] stays a NON-positioned stack child so it keeps its own aspect
/// ratio and the stack takes its size. `Positioned.fill` would force the
/// box's ratio onto a 200x248 drawing and squash the head sideways, which is
/// the one thing worse than a small one.
class _SideLabelled extends StatelessWidget {
  const _SideLabelled({required this.child, required this.inset});

  final Widget child;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTextStyle.labelTiny.copyWith(
      color: AppColors.textSecondary,
    );

    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: child,
        ),
        // Centred in the gutter rather than jammed against the screen edge,
        // which is where left: 0 alone put them.
        Positioned(
          top: 0,
          left: 0,
          width: inset,
          child: Text('L', textAlign: TextAlign.center, style: style),
        ),
        Positioned(
          top: 0,
          right: 0,
          width: inset,
          child: Text('R', textAlign: TextAlign.center, style: style),
        ),
      ],
    );
  }
}
