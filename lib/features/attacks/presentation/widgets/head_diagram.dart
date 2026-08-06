import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/head_location.dart';

/// Top half of the location step: a calm, hand-drawn front-facing head.
/// Whichever [selected] region the user picked from the list below (see
/// [LocationStep]) fills in as a bounded, shaded area on the head's own
/// silhouette. Picking [HeadLocation.back] turns the head around and tints
/// it whole, since the back can't be shown on a front-facing face.
class HeadDiagram extends StatelessWidget {
  const HeadDiagram({required this.selected, super.key});

  final HeadLocation? selected;

  /// Natural head proportions — a little taller than wide.
  static const _aspectRatio = 0.82;

  @override
  Widget build(BuildContext context) {
    final targetAngle = selected == HeadLocation.back ? math.pi : 0.0;
    return AspectRatio(
      aspectRatio: _aspectRatio,
      // No key on the angle tween: animates from the *current* angle instead
      // of snapping, so picking a side while facing away turns back smoothly.
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: targetAngle),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
        builder: (context, angle, child) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          // Ripple pulse restarts per selection (keyed): fresh pick re-animates.
          child: TweenAnimationBuilder<double>(
            key: ValueKey(selected),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, pulse, _) => CustomPaint(
              painter: _HeadPainter(
                selected: selected,
                pulse: pulse,
                angle: angle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the head silhouette, an abstract face, its 2.5D shading, and the
/// selected region's highlight. [angle] is the current Y-rotation (0 = face
/// on, π = back); [pulse] is the per-selection ripple driver.
class _HeadPainter extends CustomPainter {
  const _HeadPainter({
    required this.selected,
    required this.pulse,
    required this.angle,
  });

  final HeadLocation? selected;
  final double pulse;
  final double angle;

  /// The forehead band, as a fraction of head height from the top.
  static const _frontBandHeight = 0.42;

  static Path _outline(Size s) {
    final w = s.width;
    final h = s.height;
    return Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.83, h * 0.02, w * 0.98, h * 0.3, w * 0.94, h * 0.46)
      ..cubicTo(w * 0.91, h * 0.66, w * 0.76, h * 0.93, w * 0.5, h * 1.0)
      ..cubicTo(w * 0.24, h * 0.93, w * 0.09, h * 0.66, w * 0.06, h * 0.46)
      ..cubicTo(w * 0.02, h * 0.3, w * 0.17, h * 0.02, w * 0.5, 0)
      ..close();
  }

  static Path? _region(HeadLocation? location, Size s, Path outline) {
    switch (location) {
      case HeadLocation.left:
        return Path.combine(
          PathOperation.intersect,
          outline,
          Path()..addRect(Rect.fromLTWH(0, 0, s.width * 0.5, s.height)),
        );
      case HeadLocation.right:
        return Path.combine(
          PathOperation.intersect,
          outline,
          Path()
            ..addRect(Rect.fromLTWH(s.width * 0.5, 0, s.width * 0.5, s.height)),
        );
      case HeadLocation.front:
        return Path.combine(
          PathOperation.intersect,
          outline,
          Path()..addRect(
            Rect.fromLTWH(0, 0, s.width, s.height * _frontBandHeight),
          ),
        );
      case HeadLocation.whole:
      case HeadLocation.back:
        return outline;
      case null:
        return null;
    }
  }

  void _paintFace(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;

    // Ears — a touch larger than before.
    final earFill = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary.withValues(alpha: 0.1);
    final earStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.primary.withValues(alpha: 0.5);
    for (final dx in [0.05, 0.95]) {
      final ear = Rect.fromCenter(
        center: Offset(w * dx, h * 0.5),
        width: w * 0.08,
        height: h * 0.11,
      );
      canvas
        ..drawOval(ear, earFill)
        ..drawOval(ear, earStroke);
    }

    // Eyes — bigger, set a little wider.
    final eyePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.textSecondary.withValues(alpha: 0.62);
    final eyeSize = Size(w * 0.085, h * 0.042);
    for (final dx in [-0.21, 0.21]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * (0.5 + dx), h * 0.42),
          width: eyeSize.width,
          height: eyeSize.height,
        ),
        eyePaint,
      );
    }

    // Nose — larger curved stroke.
    final nose = Path()
      ..moveTo(w * 0.5, h * 0.45)
      ..quadraticBezierTo(w * 0.6, h * 0.57, w * 0.5, h * 0.63);
    canvas.drawPath(
      nose,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = AppColors.textSecondary.withValues(alpha: 0.5),
    );

    // Mouth — calm, neutral, a bit wider.
    canvas.drawLine(
      Offset(w * 0.38, h * 0.72),
      Offset(w * 0.62, h * 0.72),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = AppColors.textSecondary.withValues(alpha: 0.45),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size;
    final rect = Offset.zero & s;
    final outline = _outline(s);
    // 1 facing us, 0 edge-on, and back-side clamps to 0.
    final facingFront = math.cos(angle).clamp(0.0, 1.0);
    final isBack = selected == HeadLocation.back;

    _paintVolume(canvas, s, rect, outline);

    // Face only shows while we face front — fades out through the turn.
    final faceAlpha = (facingFront * 255).round().clamp(0, 255);
    if (faceAlpha > 0) {
      canvas.saveLayer(
        rect,
        Paint()..color = Color.fromARGB(faceAlpha, 255, 255, 255),
      );
      _paintFace(canvas, s);
      canvas.restore();
    }

    // Front regions reveal as we face front; "back" reveals as we turn away.
    final reveal = isBack ? (1 - facingFront) : pulse * facingFront;
    _paintRegion(canvas, s, rect, outline, reveal);

    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.primary.withValues(alpha: 0.55),
    );
  }

  /// 2.5D shading: a radial base gradient (light from the upper-left), a
  /// soft blurred rim read as inner shadow, and a faint forehead specular.
  void _paintVolume(Canvas canvas, Size s, Rect rect, Path outline) {
    final w = s.width;
    final h = s.height;

    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.45),
          radius: 1.1,
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ).createShader(rect),
    );

    canvas.save();
    canvas.clipPath(outline);

    // Inner shadow.
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.07
        ..color = AppColors.background.withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.035),
    );

    // Specular sheen.
    final specCenter = Offset(w * 0.37, h * 0.19);
    final specRect = Rect.fromCircle(center: specCenter, radius: w * 0.3);
    canvas.drawRect(
      specRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.textPrimary.withValues(alpha: 0.12),
            AppColors.textPrimary.withValues(alpha: 0),
          ],
        ).createShader(specRect),
    );

    canvas.restore();
  }

  /// Fills the selected region with a curve-following radial gradient,
  /// rippling out from its centre as [reveal] runs 0→1.
  void _paintRegion(
    Canvas canvas,
    Size s,
    Rect rect,
    Path outline,
    double reveal,
  ) {
    if (reveal <= 0) return;
    final region = _region(selected, s, outline);
    if (region == null) return;

    final bounds = region.getBounds();
    final center = bounds.center;
    final shader =
        RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.6),
            AppColors.primary.withValues(alpha: 0.2),
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: bounds.longestSide * 0.6),
        );

    canvas.saveLayer(
      rect,
      Paint()
        ..color = Color.fromARGB(
          (reveal * 255).round().clamp(0, 255),
          255,
          255,
          255,
        ),
    );
    canvas.clipPath(outline);
    canvas
      ..translate(center.dx, center.dy)
      ..scale(0.78 + 0.22 * reveal)
      ..translate(-center.dx, -center.dy);
    canvas.drawPath(region, Paint()..shader = shader);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HeadPainter oldDelegate) =>
      oldDelegate.selected != selected ||
      oldDelegate.pulse != pulse ||
      oldDelegate.angle != angle;
}
