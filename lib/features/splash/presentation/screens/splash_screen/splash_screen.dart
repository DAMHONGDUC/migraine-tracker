import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/router/app_router.dart';
import '../../../providers.dart';
import '../../widgets/splash_dots.dart';

/// Where every launch lands: the same dots `FreshInstallGate` was showing,
/// over `SplashController.run`, then the app.
///
/// The device check is not here — it has already finished by the time this
/// route can mount, because the gate above the app is what let the tree build
/// at all. What is left is the session the callables need.
class SplashScreen extends HookConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      unawaited(
        ref.read(splashControllerProvider).run().then((_) {
          // The route can be gone by now — a deep link, or the app being killed mid-launch.
          if (!context.mounted) return;

          // And it can still be mounted while no longer being what the user is
          // looking at: a deep link pushed on top leaves this route in the
          // stack underneath, and `go` from here would throw that screen away.
          // Both tap listeners wait for this hand-over now, so this is the
          // backstop for a tap that arrives DURING the splash rather than
          // before it.
          if (GoRouter.of(context).state.matchedLocation !=
              AppRoutes.splash.path) {
            return;
          }
          context.go(AppRoutes.dashboard.path);
        }),
      );

      return null;
    }, const <Object?>[]);

    return const SplashDots();
  }
}
