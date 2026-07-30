import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'liquid_glass_theme.dart';

/// Wraps a single small chrome element — an icon button, a back arrow — in
/// its own frosted Liquid Glass circle. Falls back to plain [child] when
/// [AppGlass.isSupported] is off, so every caller can use this
/// unconditionally instead of re-deriving that check itself.
///
/// For icons sitting on anything that is not itself a [LiquidGlass] surface:
/// the app bar's blurred strip ([MainAppBar]'s leading/icon actions) or a flat
/// opaque panel (a bottom sheet's [AppSheetHeader]). Both leave real
/// background under the circle to refract. Do NOT use it inside something
/// that IS already a [LiquidGlass] surface — the paywall's own header —
/// because nesting one glass layer in another has nothing left to catch the
/// light and just reads as flat.
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
