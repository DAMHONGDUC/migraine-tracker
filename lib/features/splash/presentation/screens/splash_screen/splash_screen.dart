import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/splash_constant.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';

/// The app icon and a loading indicator, held for [SplashConstant.minimumVisible] before the app itself.
///
/// It waits on nothing: `AppBootstrap.init` runs before `runApp`, so everything is ready by the first frame. The timer leaves for the dashboard and the router's own redirect sends a first launch on to onboarding — one owner for that decision, here as everywhere.
class SplashScreen extends HookConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      final Timer timer = Timer(SplashConstant.minimumVisible, () {
        // A pushed route or a killed app can outlive the timer; navigating then throws on a dead element.
        if (context.mounted) context.go(AppRoutes.dashboard.path);
      });

      return timer.cancel;
    }, const <Object?>[]);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Square, at the same size the native launch screen draws it: that screen is a storyboard image view and cannot round anything, so a rounded copy here would pop the moment Flutter took over.
            Image.asset(
              SplashConstant.iconAsset,
              width: SplashConstant.iconSize.r,
              height: SplashConstant.iconSize.r,
              // The icon is the app's own mark; a screen reader has nothing to gain from it and the label would be the app name it already announced.
              excludeFromSemantics: true,
            ),
            SizedBox(height: SdSpacingConstant.h32),
            LoadingAnimationWidget.staggeredDotsWave(
              color: AppColors.primary,
              size: SplashConstant.dotsSize.r,
            ),
          ],
        ),
      ),
    );
  }
}
