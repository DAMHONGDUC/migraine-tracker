import 'package:flutter/material.dart';

/// Tactile feedback that swells instead of shrinking: a touch grows the
/// child to [peakScale] and settles it straight back to full size.
///
/// The counterpart to [PressableScale], which presses *in*. Use this where
/// the target is small and the finger covers it — an app-bar icon, the nav
/// pill — so the feedback appears around the fingertip rather than under it.
///
/// It only *observes* the touch: a translucent [Listener] on raw pointer
/// events, so it never enters the gesture arena and whatever handles the tap
/// underneath keeps working, including a long press. The scale is
/// paint-only; layout never moves.
class PopScale extends StatefulWidget {
  const PopScale({
    required this.child,
    this.peakScale = 1.18,
    this.alignment = Alignment.center,
    super.key,
  });

  final Widget child;

  /// Peak of the overshoot, relative to full size (1.0).
  final double peakScale;

  /// What the swell grows away from. Centre for something free-standing; an
  /// edge for something anchored to one (the nav pill keeps its bottom edge
  /// on the safe-area line and grows upward).
  final Alignment alignment;

  @override
  State<PopScale> createState() => _PopScaleState();
}

class _PopScaleState extends State<PopScale>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 350);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  );

  /// Out to the peak on the first 40% of the run, back to rest over the
  /// remaining 60% — the return is the slower half, so it reads as settling
  /// rather than snapping (hard rule 3: calm, never a flash).
  late final Animation<double> _scale = _controller.drive(
    TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        weight: 40,
        tween: Tween<double>(
          begin: 1,
          end: widget.peakScale,
        ).chain(CurveTween(curve: Curves.easeOut)),
      ),
      TweenSequenceItem<double>(
        weight: 60,
        tween: Tween<double>(
          begin: widget.peakScale,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOut)),
      ),
    ]),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (PointerDownEvent _) => _controller.forward(from: 0),
      child: ScaleTransition(
        scale: _scale,
        alignment: widget.alignment,
        child: widget.child,
      ),
    );
  }
}
