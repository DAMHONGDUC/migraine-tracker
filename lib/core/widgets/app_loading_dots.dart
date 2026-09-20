import 'package:flutter/widgets.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../theme/app_colors.dart';

/// The app's one waiting animation — the dots a launch shows, centred in
/// whatever space it is given.
///
/// **One owner, because a second wait that looked different would read as a
/// second kind of wait.** The launch draws it through `SplashDots` and the
/// head picker draws it while the model loads; both are the app holding still
/// until something it cannot hurry arrives, so both say it the same way.
///
/// **It reads nothing off its context** — no theme, no `MediaQuery`, no
/// `Material`. `FreshInstallGate` draws it above `MaterialApp`, where none of
/// those exist yet, and a widget that works there works everywhere.
class AppLoadingDots extends StatelessWidget {
  const AppLoadingDots({required this.size, super.key});

  /// Raw logical pixels, never `.r`: the launch draws this above
  /// `ScreenUtilInit`, where the scale is not registered.
  final double size;

  @override
  Widget build(BuildContext context) => Center(
    child: LoadingAnimationWidget.staggeredDotsWave(
      color: AppColors.primary,
      size: size,
    ),
  );
}
