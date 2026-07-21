import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/head_location.dart';

/// Top half of the location step: a calm, hand-drawn front-facing head
/// outline. Whichever [selected] region the user picked from the list
/// below (see [LocationStep]) is filled in as an actual bounded area —
/// clipped to the head's own silhouette via [Path.combine] — not a
/// floating glow. Picking [HeadLocation.back] turns the head around (a
/// flip animation, face hidden) and tints the whole silhouette, since the
/// back can't be shown as a spot on a front-facing outline.
class HeadDiagram extends StatelessWidget {
  const HeadDiagram({required this.selected, super.key});

  final HeadLocation? selected;

  /// Natural head proportions — a little taller than wide.
  static const _aspectRatio = 0.82;

  @override
  Widget build(BuildContext context) {
    final isBack = selected == HeadLocation.back;
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(selected),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        builder: (context, t, child) => Transform(
          alignment: Alignment.center,
          // A gentle 3D turn (only for "back") — perspective entry gives
          // the flip real depth instead of a flat horizontal squash.
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(isBack ? t * math.pi : 0),
          child: CustomPaint(
            painter: _HeadPainter(selected: selected, pulse: t),
          ),
        ),
      ),
    );
  }
}

/// Draws the head silhouette, an abstract face, and — if [selected] is
/// set — the matching highlight. [pulse] animates 0→1 right after a new
/// selection so the fill/turn visibly happens rather than snapping in.
class _HeadPainter extends CustomPainter {
  const _HeadPainter({required this.selected, required this.pulse});

  final HeadLocation? selected;
  final double pulse;

  /// The forehead band, as a fraction of head height from the top.
  static const _frontBandHeight = 0.42;

  static Path _outline(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.83, h * 0.02, w * 0.98, h * 0.3, w * 0.94, h * 0.46)
      ..cubicTo(w * 0.91, h * 0.66, w * 0.76, h * 0.93, w * 0.5, h * 1.0)
      ..cubicTo(w * 0.24, h * 0.93, w * 0.09, h * 0.66, w * 0.06, h * 0.46)
      ..cubicTo(w * 0.02, h * 0.3, w * 0.17, h * 0.02, w * 0.5, 0)
      ..close();
  }

  /// The tappable region's shape, bounded to the head's own silhouette.
  /// Null for [HeadLocation.back] (filled whole in [paint] instead) and
  /// for no selection.
  static Path? _region(HeadLocation? location, Size size, Path outline) {
    switch (location) {
      case HeadLocation.left:
        return Path.combine(
          PathOperation.intersect,
          outline,
          Path()..addRect(Rect.fromLTWH(0, 0, size.width * 0.5, size.height)),
        );
      case HeadLocation.right:
        return Path.combine(
          PathOperation.intersect,
          outline,
          Path()..addRect(
            Rect.fromLTWH(size.width * 0.5, 0, size.width * 0.5, size.height),
          ),
        );
      case HeadLocation.front:
        return Path.combine(
          PathOperation.intersect,
          outline,
          Path()..addRect(
            Rect.fromLTWH(0, 0, size.width, size.height * _frontBandHeight),
          ),
        );
      case HeadLocation.whole:
      case HeadLocation.back:
        return outline;
      case null:
        return null;
    }
  }

  void _paintFace(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ears: small ovals hugging the head's widest point, half-overlapping
    // the outline so they read as attached, not floating.
    final earFill = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary.withValues(alpha: 0.1);
    final earStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.primary.withValues(alpha: 0.5);
    for (final dx in [0.055, 0.945]) {
      final ear = Rect.fromCenter(
        center: Offset(w * dx, h * 0.5),
        width: w * 0.07,
        height: h * 0.09,
      );
      canvas
        ..drawOval(ear, earFill)
        ..drawOval(ear, earStroke);
    }

    // Eyes.
    final eyePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.textSecondary.withValues(alpha: 0.6);
    final eyeSize = Size(w * 0.07, h * 0.035);
    for (final dx in [-0.19, 0.19]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * (0.5 + dx), h * 0.42),
          width: eyeSize.width,
          height: eyeSize.height,
        ),
        eyePaint,
      );
    }

    // Nose: an abstract curved stroke — bigger than a straight tick so it
    // actually reads as a nose rather than a stray mark.
    final nose = Path()
      ..moveTo(w * 0.5, h * 0.46)
      ..quadraticBezierTo(w * 0.58, h * 0.56, w * 0.5, h * 0.62);
    canvas.drawPath(
      nose,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = AppColors.textSecondary.withValues(alpha: 0.5),
    );

    // Mouth: a calm, neutral line — no smile/frown on a "where does it
    // hurt" screen (hard rule 3: nothing that could read as flippant).
    canvas.drawLine(
      Offset(w * 0.4, h * 0.71),
      Offset(w * 0.6, h * 0.71),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..color = AppColors.textSecondary.withValues(alpha: 0.45),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outline = _outline(size);
    final isBack = selected == HeadLocation.back;

    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.fill
        ..color = AppColors.primary.withValues(alpha: 0.1),
    );

    // No face on the back of the head — fades out as the turn completes.
    final faceAlpha = isBack
        ? (255 - (pulse * 2 * 255).round()).clamp(0, 255)
        : 255;
    if (faceAlpha > 0) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Color.fromARGB(faceAlpha, 255, 255, 255),
      );
      _paintFace(canvas, size);
      canvas.restore();
    }

    final region = _region(selected, size, outline);
    if (region != null) {
      canvas.drawPath(
        region,
        Paint()
          ..style = PaintingStyle.fill
          ..color = AppColors.primary.withValues(alpha: 0.4 * pulse),
      );
    }

    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.primary.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _HeadPainter oldDelegate) =>
      oldDelegate.selected != selected || oldDelegate.pulse != pulse;
}
