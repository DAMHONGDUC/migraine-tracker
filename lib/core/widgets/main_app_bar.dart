import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'glass/liquid_glass_theme.dart';

/// The app's single, frosted Liquid Glass [AppBar]. Every screen gets it via
/// [AppScaffold] rather than constructing an [AppBar] directly.
///
/// It relies on `Scaffold(extendBodyBehindAppBar: true)` (which [AppScaffold]
/// sets) so the body scrolls *behind* the bar and the glass has something to
/// refract — without that it just tints the near-black background and the
/// effect is invisible. Scroll-under bodies should pad their top by
/// [bodyTopInset] so their first item starts below the bar.
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

  /// Top inset a scroll-under body needs: the status-bar height plus the
  /// toolbar (and any [bottom]) so the first item clears the bar. Returns 0
  /// when glass is disabled — the bar is then opaque and the body sits below
  /// it normally, so no extra inset is wanted.
  static double bodyTopInset(BuildContext context, {double bottomHeight = 0}) =>
      kLiquidGlassEnabled
      ? MediaQuery.paddingOf(context).top + kToolbarHeight + bottomHeight
      : 0;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      backgroundColor: kLiquidGlassEnabled ? Colors.transparent : null,
      elevation: kLiquidGlassEnabled ? 0 : null,
      scrolledUnderElevation: kLiquidGlassEnabled ? 0 : null,
      surfaceTintColor: kLiquidGlassEnabled ? Colors.transparent : null,
      title: title,
      actions: actions,
      leading: leading,
      bottom: bottom,
    );
    if (!kLiquidGlassEnabled) return appBar;
    return LiquidGlass.withOwnLayer(
      settings: kChromeGlass,
      // Edge-to-edge frosted bar; the title/actions paint crisply on top
      // (glassContainsChild: false) so text is never refracted.
      shape: const LiquidRoundedRectangle(borderRadius: 0),
      child: appBar,
    );
  }
}
