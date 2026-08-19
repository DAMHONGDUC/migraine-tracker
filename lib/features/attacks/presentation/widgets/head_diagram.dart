import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/head_location.dart';

/// Top half of the location step: a calm, hand-drawn head, now two SVG
/// assets rather than a hand-painted face. Whichever [selected] region the
/// user picked from the list below (see [LocationStep]) fills in as a
/// bounded, shaded area on the head's own silhouette. Picking
/// [HeadLocation.back] turns the head around — the turn swaps
/// `head_front.svg` for `head_back.svg` halfway through — and tints it
/// whole, since the back can't be shown on a front-facing face.
///
/// Deliberately a raw [SvgPicture] rather than an `SdIconV2`, which the
/// design system otherwise requires: that widget forces a square box and
/// paints the whole asset in one `srcIn` colour, which would flatten a
/// multi-tone 100×122 illustration into a silhouette. Ask before copying
/// this exemption anywhere else — an icon is still an `SdIconV2`.
class HeadDiagram extends StatelessWidget {
  const HeadDiagram({required this.selected, super.key});

  final HeadLocation? selected;

  /// Natural head proportions — a little taller than wide. Matches the
  /// 100×122 viewBox both SVGs are drawn on.
  static const double _aspectRatio = 0.82;

  static const String _frontAsset = 'assets/images/head_front.svg';
  static const String _backAsset = 'assets/images/head_back.svg';

  @override
  Widget build(BuildContext context) {
    final double targetAngle = selected == HeadLocation.back ? math.pi : 0.0;

    return AspectRatio(
      aspectRatio: _aspectRatio,
      // No key on the angle tween: animates from the *current* angle instead
      // of snapping, so picking a side while facing away turns back smoothly.
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: targetAngle),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
        builder: (BuildContext context, double angle, Widget? _) {
          final bool facingFront = math.cos(angle) >= 0;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: Transform(
              alignment: Alignment.center,
              // Past a quarter turn the outer rotation mirrors everything it
              // carries. Undo that for the far side so the back artwork —
              // and any highlight on it — is not drawn inside out.
              transform: facingFront
                  ? Matrix4.identity()
                  : (Matrix4.identity()..rotateY(math.pi)),
              // Ripple pulse restarts per selection (keyed): fresh pick
              // re-animates.
              child: TweenAnimationBuilder<double>(
                key: ValueKey<HeadLocation?>(selected),
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                builder: (BuildContext context, double pulse, Widget? child) {
                  return CustomPaint(
                    foregroundPainter: _RegionPainter(
                      selected: selected,
                      pulse: pulse,
                      angle: angle,
                    ),
                    child: child,
                  );
                },
                // BoxFit.fill, not contain: the painter above stretches its
                // outline to the full box, so the artwork has to as well or
                // the highlight drifts off the silhouette wherever something
                // overrides the [AspectRatio] (a tight ListView child does).
                child: SvgPicture.asset(
                  facingFront ? _frontAsset : _backAsset,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Paints only the selected region's highlight, over the SVG head. The
/// silhouette it clips to is the same curve both assets are drawn from, in
/// the same 100×122 proportions — edit one and you must edit the others.
/// [angle] is the current Y-rotation (0 = face on, π = back); [pulse] is the
/// per-selection ripple driver.
class _RegionPainter extends CustomPainter {
  const _RegionPainter({
    required this.selected,
    required this.pulse,
    required this.angle,
  });

  final HeadLocation? selected;
  final double pulse;
  final double angle;

  /// The forehead band, as a fraction of head height from the top.
  static const double _frontBandHeight = 0.42;

  static Path _outline(Size s) {
    final double w = s.width;
    final double h = s.height;

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

  @override
  void paint(Canvas canvas, Size size) {
    // 1 facing us, 0 edge-on, and the back side clamps to 0.
    final double facingFront = math.cos(angle).clamp(0.0, 1.0);
    final bool isBack = selected == HeadLocation.back;

    // Front regions reveal as we face front; "back" reveals as we turn away.
    final double reveal = isBack ? (1 - facingFront) : pulse * facingFront;
    if (reveal <= 0) return;

    final Path outline = _outline(size);
    final Path? region = _region(selected, size, outline);
    if (region == null) return;

    final Rect rect = Offset.zero & size;
    final Rect bounds = region.getBounds();
    final Offset center = bounds.center;
    final Shader shader =
        RadialGradient(
          colors: <Color>[
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
  bool shouldRepaint(covariant _RegionPainter oldDelegate) =>
      oldDelegate.selected != selected ||
      oldDelegate.pulse != pulse ||
      oldDelegate.angle != angle;
}
