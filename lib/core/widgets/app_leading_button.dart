import 'package:flutter/material.dart';

/// The one leading (top-left) app-bar button for the whole app — every
/// screen's back/step-back action goes through this so they all share the
/// same icon size, padding, and tap-target policy instead of each screen
/// hand-rolling its own [IconButton].
///
/// Uses the default [IconButton] metrics (icon size, padding, 48×48 tap
/// target) so it matches the app bar's icon *actions* exactly — inside
/// [MainAppBar] both get the same frosted [GlassCircle], so a matching
/// footprint keeps the leading circle and the action circles the same size.
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
    );
  }
}
