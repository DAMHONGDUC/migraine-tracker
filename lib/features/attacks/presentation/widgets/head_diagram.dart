import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/enums/head_region.dart';
import 'head_region_geometry.dart';
import 'head_region_painter.dart';

/// The head itself: line art from an SVG, with every tapped area filled
/// underneath it by [HeadRegionPainter].
///
/// Deliberately a raw [SvgPicture] rather than an `SdIconV2`, which the
/// design system otherwise requires: that widget forces a square box and
/// paints the whole asset in one `srcIn` colour, which is right for an icon
/// and wrong for a 200×220 illustration. Ask before copying this exemption —
/// an icon is still an `SdIconV2`.
///
/// [onRegionTapped] null makes it read-only, which is how the attack detail
/// screen draws a saved attack.
class HeadDiagram extends StatelessWidget {
  const HeadDiagram({
    required this.selected,
    required this.view,
    this.onRegionTapped,
    super.key,
  });

  final List<HeadRegion> selected;
  final HeadView view;
  final ValueChanged<HeadRegion>? onRegionTapped;

  static const Map<HeadView, String> _assets = <HeadView, String>{
    HeadView.front: 'assets/images/head_front.svg',
    HeadView.back: 'assets/images/head_back.svg',
  };

  @override
  Widget build(BuildContext context) {
    final ValueChanged<HeadRegion>? onTapped = onRegionTapped;

    return AspectRatio(
      aspectRatio: HeadRegionGeometry.aspectRatio,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size size = constraints.biggest;

          return GestureDetector(
            // Opaque, not deferToChild: the SVG is mostly transparent, so
            // hit-testing the child would only ever catch the strokes.
            behavior: HitTestBehavior.opaque,
            onTapUp: onTapped == null
                ? null
                : (TapUpDetails details) {
                    final HeadRegion? region = HeadRegionGeometry.hitTest(
                      details.localPosition,
                      view,
                      size,
                    );
                    // A tap that missed the head does nothing. Snapping to the
                    // nearest area would log a place the user did not point at.
                    if (region != null) onTapped(region);
                  },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              // SizedBox.expand is load bearing: AnimatedSwitcher stacks its
              // children under LOOSE constraints, where SvgPicture takes the
              // asset's own 200x248 and ignores any bigger box.
              child: SizedBox.expand(
                key: ValueKey<HeadView>(view),
                child: CustomPaint(
                  // The key is on the SizedBox above: the switcher's direct
                  // child is what has to change identity to cross-fade. Keyed
                  // on the view alone, so a fill lands instantly.
                  painter: HeadRegionPainter(view: view, selected: selected),
                  // BoxFit.fill, not contain: the painter stretches the same
                  // design box to the full widget, so the artwork must too or
                  // the fills drift off wherever [AspectRatio] is overridden.
                  child: SvgPicture.asset(_assets[view]!, fit: BoxFit.fill),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
