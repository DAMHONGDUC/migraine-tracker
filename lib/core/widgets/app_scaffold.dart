import 'package:flutter/material.dart';

import '../constants/app_spacing_constant.dart';
import 'glass/liquid_glass_theme.dart';
import 'main_app_bar.dart';

/// The app's standard screen scaffold. Every top-level screen uses this
/// instead of a bare [Scaffold] so the frosted [MainAppBar] and the
/// behind-the-bar layout are wired in one place.
///
/// When [AppGlass.isSupported] is true it sets `extendBodyBehindAppBar` so the
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
    this.bottomNavigationBar,
    this.withSafeArea = true,
    super.key,
  });

  final Widget title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? appBarBottom;
  final Widget? floatingActionButton;

  /// A bottom bar (e.g. the log flow's floating step progress). When set and
  /// glass is on, the body extends behind it so it refracts through the glass;
  /// pad the body's bottom by [bottomBarInset] so its last item clears it.
  final Widget? bottomNavigationBar;

  /// Keeps [body] clear of the home indicator and side insets, so screens
  /// stop repeating `MediaQuery.paddingOf(context).bottom`.
  ///
  /// Top is excluded — that edge is the app bar's, and a scroll-under body
  /// passes behind it via [bodyTopInset] from inside the scrollable.
  ///
  /// Pass false where content scrolls behind a floating bottom bar (the tab
  /// screens, the log flow): a bottom SafeArea would cut the viewport short.
  final bool withSafeArea;

  /// Top inset a scroll-under body should pad by so its first item clears the
  /// frosted bar. Read it inside [body] (e.g. a `ListView.padding`).
  static double bodyTopInset(BuildContext context) =>
      MainAppBar.bodyTopInset(context);

  /// Bottom inset a scroll-under body on a *tab* screen should pad by so its
  /// last item clears the floating glass bottom nav (which content scrolls
  /// behind): safe area + bar height + a small breathing gap.
  ///
  /// Reads `viewPadding` (the raw device inset), NOT `padding`: Scaffold
  /// rewrites the body's `MediaQuery.padding.bottom` to the nav slot height
  /// under `extendBody`, so a `padding` read returns different values above
  /// vs inside the body — `viewPadding` is stable everywhere.
  ///
  /// Never collapses: the shell's nav is a floating pill on every device
  /// (see [AppGlass]), so the body always scrolls behind it.
  static double bottomNavInset(BuildContext context) =>
      MediaQuery.viewPaddingOf(context).bottom +
      AppSpacingConstant.h68 + // shared bar height (nav + progress)
      AppSpacingConstant.h8;

  /// Same measurement for a floating bar passed as [bottomNavigationBar] —
  /// the log flow's step bar. Unlike the shell nav that one is only floating
  /// where glass is supported, so this collapses to 0 otherwise: the bar
  /// then reserves its own layout slot and the body must not pad for it.
  static double bottomBarInset(BuildContext context) =>
      AppGlass.isSupported ? bottomNavInset(context) : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: AppGlass.isSupported,
      // Let the body flow behind a floating glass bottom bar so it refracts
      // through it (mirrors the shell's bottom nav).
      extendBody: AppGlass.isSupported && bottomNavigationBar != null,
      appBar: MainAppBar(
        title: title,
        actions: actions,
        leading: leading,
        bottom: appBarBottom,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      // Tap anywhere outside a focused field (e.g. the medications search box)
      // to drop focus and dismiss the keyboard. Translucent so it never eats
      // taps meant for buttons/list rows — a tap only reaches here when nothing
      // nearer claims it; a scroll drag defeats the tap so scrolling is
      // unaffected.
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: _wrapped(),
      ),
    );
  }

  /// SafeArea outside any scroll view the body brings (see [AppActionView]),
  /// so content stops clear of the home indicator instead of running under
  /// it.
  Widget _wrapped() => withSafeArea ? SafeArea(top: false, child: body) : body;
}
