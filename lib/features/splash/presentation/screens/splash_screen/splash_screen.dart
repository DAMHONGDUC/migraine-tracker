import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../../../core/constants/splash_constant.dart';
import '../../../../../core/theme/app_colors.dart';

/// What the user looks at while `AppBootstrap.init` runs: the app icon the native launch screen was already showing, plus the dots that say it is working.
///
/// Sizes here are raw logical pixels rather than `.r`/`SdSpacingConstant`, and they have to be: this screen lives ABOVE the app, outside the `ScreenUtilInit` that gives those their scale. Two centred elements do not need it.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Square, at the size the native launch screen draws it: that screen is a storyboard image view and cannot round anything, so a rounded copy here would pop the moment Flutter took over.
            Image.asset(
              SplashConstant.iconAsset,
              width: SplashConstant.iconSize,
              height: SplashConstant.iconSize,
              // The icon is the app's own mark; a screen reader has nothing to gain from it and the label would be the app name it already announced.
              excludeFromSemantics: true,
            ),
            const SizedBox(height: SplashConstant.iconToDotsGap),
            LoadingAnimationWidget.staggeredDotsWave(
              color: AppColors.primary,
              size: SplashConstant.dotsSize,
            ),
          ],
        ),
      ),
    );
  }
}
