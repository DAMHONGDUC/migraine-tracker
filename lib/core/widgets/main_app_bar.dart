import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../theme/app_colors.dart';
import 'glass/liquid_glass_theme.dart';

/// The app's single [AppBar]. Every screen gets it via [AppScaffold] rather
/// than constructing an [AppBar] directly.
///
/// Chrome style: the bar itself is NOT a glass slab — its strip is the app
/// background colour (translucent) over a backdrop blur, so there is no
/// visible edge/divider and content scrolling behind it (via
/// `extendBodyBehindAppBar`) simply blurs out. The Liquid Glass treatment
/// is applied per element instead: the leading/back button and icon actions
/// each sit in their own glass circle. Scroll-under bodies should pad their
/// top by [bodyTopInset] so their first item starts below the bar.
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({
    required this.title,
    this.actions,
    this.leading,
    this.bottom,
    super.key,
  });

  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  /// Top inset a scroll-under body needs so its first item clears the bar:
  /// status bar + toolbar.
  ///
  /// Reads `viewPadding` (the raw device inset), NOT `padding`: Scaffold
  /// rewrites the body's `MediaQuery.padding.top` to the app-bar height
  /// under `extendBodyBehindAppBar`, so a `padding` read returns different
  /// values above vs inside the body — `viewPadding` is stable everywhere.
  /// Returns 0 when glass is disabled — the bar is then opaque and the body
  /// sits below it normally.
  static double bodyTopInset(BuildContext context) => kLiquidGlassEnabled
      ? MediaQuery.viewPaddingOf(context).top + kToolbarHeight
      : 0;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    if (!kLiquidGlassEnabled) {
      return AppBar(
        title: title,
        actions: actions,
        leading: leading,
        bottom: bottom,
      );
    }

    // Glass per element: the (back) button and plain icon actions get their
    // own circles. Composite actions (filter pill, view toggle) already
    // carry their own surface, so they pass through untouched.
    Widget? glassLeading = leading;
    if (glassLeading == null && (ModalRoute.of(context)?.canPop ?? false)) {
      glassLeading = const BackButton();
    }
    if (glassLeading != null) {
      glassLeading = _GlassCircle(child: glassLeading);
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: kChromeGlass.blur,
          sigmaY: kChromeGlass.blur,
        ),
        // Same colour as the app background — no divider, no distinct slab;
        // the translucency lets the blurred content glow through faintly.
        child: ColoredBox(
          color: AppColors.background.withValues(alpha: 0.65),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            title: title,
            leading: glassLeading,
            actions: [
              for (final action in actions ?? const <Widget>[])
                if (action is IconButton)
                  _GlassCircle(child: action)
                else
                  action,
            ],
            bottom: bottom,
          ),
        ),
      ),
    );
  }
}

/// A single app-bar element in its own Liquid Glass circle.
class _GlassCircle extends StatelessWidget {
  const _GlassCircle({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass.withOwnLayer(
      settings: kChromeGlass,
      shape: const LiquidOval(),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
