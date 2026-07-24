import 'package:flutter/material.dart';

import '../constants/app_spacing_constant.dart';

/// The one leading (top-left) app-bar button for the whole app — every
/// screen's back/step-back action goes through this so they all share the
/// same icon size, padding, and tap-target policy instead of each screen
/// hand-rolling its own [IconButton].
///
/// Defaults to a plain platform-adaptive back arrow that pops the current
/// route ([Navigator.maybePop]) — that's what [MainAppBar] auto-inserts for
/// any pushed screen that can pop. Pass [onPressed] to repurpose it for
/// something that isn't a route pop at all: the log flow's app bar uses it
/// to step back through `LogController`'s state machine instead — its
/// "steps" are one screen's internal state (an `AnimatedSwitcher`), not
/// separate routes, so there is nothing for a real back button to pop.
class AppLeadingButton extends StatelessWidget {
  const AppLeadingButton({
    this.icon = const BackButtonIcon(),
    this.onPressed,
    super.key,
  });

  final Widget icon;

  /// Defaults to popping the current route.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: icon,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      iconSize: AppSpacingConstant.r18,
      padding: EdgeInsets.all(AppSpacingConstant.w6),
      // No minimum tap-target floor: Material's IconButton otherwise clamps
      // to 48×48 regardless of padding/icon size, which would swallow the
      // smaller footprint this button is deliberately going for — it's a
      // secondary action next to whatever primary action (e.g. "Next")
      // shares the app bar.
      constraints: const BoxConstraints(),
    );
  }
}
