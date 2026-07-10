import 'package:flutter/material.dart';

/// Wraps a tappable child with a gentle scale-down on press — tactile
/// feedback that stays calm (no flashing, small travel) for photophobic
/// users. Prefer this over a bare GestureDetector for the log flow buttons.
class PressableScale extends StatefulWidget {
  const PressableScale({
    required this.onTap,
    required this.child,
    this.pressedScale = 0.94,
    super.key,
  });

  final VoidCallback onTap;
  final Widget child;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
