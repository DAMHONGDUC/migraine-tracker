import 'package:flutter/widgets.dart';

import '../../../../core/constants/splash_constant.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loading_dots.dart';

/// The one loading look a launch has, drawn twice: by `FreshInstallGate` above
/// the app, and by `SplashScreen` as the first route under it.
///
/// **It reads nothing off its context** — no theme, no `MediaQuery`, no
/// `Material` — because the gate draws it above `MaterialApp`, where none of
/// those are registered yet. Hence the bare `Directionality` and the raw
/// colour.
class SplashDots extends StatelessWidget {
  const SplashDots({super.key});

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: ColoredBox(
      color: AppColors.background,
      child: AppLoadingDots(size: SplashConstant.dotsSize),
    ),
  );
}
