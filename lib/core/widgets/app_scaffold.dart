import 'package:flutter/material.dart';

import '../constants/app_spacing_constant.dart';
import 'glass/liquid_glass_theme.dart';
import 'main_app_bar.dart';

/// The app's standard screen scaffold. Every top-level screen uses this
/// instead of a bare [Scaffold] so the frosted [MainAppBar] and the
/// behind-the-bar layout are wired in one place.
///
/// When [kLiquidGlassEnabled] is true it sets `extendBodyBehindAppBar` so the
/// body refracts through the glass; scroll-under bodies should pad their top
/// by [bodyTopInset] (which collapses to 0 when glass is off).
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.body,
    this.actions,
    this.leading,
    this.appBarBottom,
    this.floatingActionButton,
    super.key,
  });

  final Widget title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? appBarBottom;
  final Widget? floatingActionButton;

  /// Top inset a scroll-under body should pad by so its first item clears the
  /// frosted bar. Read it inside [body] (e.g. a `ListView.padding`).
  static double bodyTopInset(BuildContext context, {double bottomHeight = 0}) =>
      MainAppBar.bodyTopInset(context, bottomHeight: bottomHeight);

  /// Standard tab-bar content height (icon + label).
  static const double _navBarHeight = 56;

  /// Bottom inset a scroll-under body on a *tab* screen should pad by so its
  /// last item clears the floating glass bottom nav (which content scrolls
  /// behind). Collapses to 0 when glass is off — the bar then reserves its own
  /// slot. Only tab screens (Log/History/Insights/Settings) need this.
  static double bottomNavInset(BuildContext context) => kLiquidGlassEnabled
      ? MediaQuery.paddingOf(context).bottom +
            _navBarHeight +
            AppSpacingConstant.h8
      : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: kLiquidGlassEnabled,
      appBar: MainAppBar(
        title: title,
        actions: actions,
        leading: leading,
        bottom: appBarBottom,
      ),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}
