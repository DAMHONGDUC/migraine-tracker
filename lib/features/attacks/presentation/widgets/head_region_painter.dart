import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/head_region.dart';
import 'head_region_geometry.dart';

/// Everything filled on the head diagram: the unselected body, the areas the
/// user tapped, and the lines between them. The line art on top of it is
/// `head_front.svg` / `head_back.svg`, which carry no fill of their own.
///
/// Draws in [HeadRegionGeometry.designSize] units and scales the canvas once,
/// so every number here reads against the SVGs and the geometry unchanged.
class HeadRegionPainter extends CustomPainter {
  const HeadRegionPainter({required this.view, required this.selected});

  final HeadView view;
  final List<HeadRegion> selected;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final Size design = HeadRegionGeometry.designSize;
    final Path outline = HeadRegionGeometry.outline(view);

    canvas
      ..save()
      ..scale(size.width / design.width, size.height / design.height);

    // The body of the head, so an untouched area still reads as a surface
    // rather than as a hole cut in the screen. It follows the view because the
    // neck is only part of the shape on the back, where the nape covers it.
    canvas.drawPath(
      outline,
      Paint()..color = AppColors.surfaceElevated.withValues(alpha: 0.6),
    );

    for (final HeadRegion region in selected) {
      final Path? path = HeadRegionGeometry.regionPath(region, view);
      if (path == null) continue;
      canvas.drawPath(
        path,
        Paint()..color = AppColors.primary.withValues(alpha: 0.45),
      );
    }

    // Dividers last and clipped, so they read as creases in the head rather
    // than as lines lying across it.
    final Path? nose = HeadRegionGeometry.regionPath(HeadRegion.nose, view);
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = AppColors.background.withValues(alpha: 0.75);

    canvas
      ..save()
      // Minus the nose: the centre line and the under-eye cut are drawn
      // straight through it and this is what erases the stretches that would
      // otherwise cross a single area. It also keeps the geometry's divider
      // list free of any special case for the nose.
      ..clipPath(
        nose == null
            ? outline
            : Path.combine(PathOperation.difference, outline, nose),
      )
      ..drawPath(HeadRegionGeometry.dividers(view), stroke)
      ..restore();

    // The nose's own outline, in the divider's colour rather than the line
    // art's white (owner's rule): it is a boundary between areas, so it has
    // to read as one. The SVG keeps only the thin strokes inside it.
    if (nose != null) {
      canvas
        ..save()
        ..clipPath(outline)
        ..drawPath(nose, stroke)
        ..restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HeadRegionPainter oldDelegate) =>
      oldDelegate.view != view || !listEquals(oldDelegate.selected, selected);
}
