import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../../../core/constants/splash_constant.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../providers.dart';

/// Where every launch lands: the loading indicator, over `SplashController.run`, then the app.
///
/// The first-launch guard lives behind this rather than in `AppBootstrap` so its work happens under something moving — before, it ran ahead of `runApp`, where the platform's launch screen stood in for it and a slow start could not be told from a hang.
class SplashScreen extends HookConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      unawaited(
        ref.read(splashControllerProvider).run().then((_) {
          // The route can be gone by now — a deep link, or the app being killed mid-launch.
          if (context.mounted) context.go(AppRoutes.dashboard.path);
        }),
      );

      return null;
    }, const <Object?>[]);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: LoadingAnimationWidget.staggeredDotsWave(
          color: AppColors.primary,
          size: SplashConstant.dotsSize,
        ),
      ),
    );
  }
}
