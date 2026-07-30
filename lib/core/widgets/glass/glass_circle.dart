import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'liquid_glass_theme.dart';

/// Wraps a single small chrome element — an icon button, a back arrow — in
/// its own frosted Liquid Glass circle. Falls back to plain [child] when
/// [AppGlass.isSupported] is off, so every caller can use this
/// unconditionally instead of re-deriving that check itself.
///
/// Only for icons sitting directly on non-glass chrome (blurred but not
/// itself a [LiquidGlass] surface) — that's what gives the circle real
/// background to refract. [MainAppBar]'s leading/icon actions are the
/// current example. Do NOT use this on an opaque surface (a bottom sheet,
/// a card) or inside something that is already a [LiquidGlass] surface:
/// either way there is nothing left of the real background to catch the
/// light and it just reads as flat.
class GlassCircle extends StatelessWidget {
  const GlassCircle({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AppGlass.isSupported) return child;
    return LiquidGlass.withOwnLayer(
      settings: kChromeGlass,
      shape: const LiquidOval(),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
