import 'package:flutter/material.dart';

import 'glass/liquid_glass_theme.dart';
import 'main_app_bar.dart';

/// The app's standard screen scaffold. Every top-level screen uses this
/// instead of a bare [Scaffold] so the frosted [MainAppBar] and the
/// behind-the-bar layout are wired in one place.
///
/// When [AppGlass.isSupported] is true it sets `extendBodyBehindAppBar` so the
/// body refracts through the glass.
///
/// It deliberately adds NO padding of its own — no SafeArea, no insets. Every
/// screen pads its own scrollable through `AppContentPadding`, so the device
/// insets are computed in exactly one place and can never be applied twice
/// (a scaffold-level SafeArea plus a body that also clears a floating bar is
/// how that used to happen).
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.body,
    this.actions,
    this.leading,
    this.appBarBottom,
    this.floatingActionButton,
    this.bottomNavigationBar,
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
  /// pad the body's bottom by `AppContentPadding.bottomBar` so its last item
  /// clears it.
  final Widget? bottomNavigationBar;

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
        child: body,
      ),
    );
  }
}
