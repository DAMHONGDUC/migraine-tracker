import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../domain/services/home_widget_link.dart';
import '../../providers.dart';

/// Turns a tap on the home-screen widget into the screen it points at.
///
/// It wraps the app rather than living on one, for the same reason
/// `NotificationTapListener` does: the tap has to be caught wherever the user
/// is, including nowhere at all yet.
///
/// Two ways in, because a tap arrives differently depending on what the app
/// was doing — one that launched it, and one that reached it already running.
/// Both resolve to the same route.
class HomeWidgetTapListener extends HookConsumerWidget {
  const HomeWidgetTapListener({required this.child, super.key});

  final Widget child;

  Future<void> _open(WidgetRef ref, Uri? uri) async {
    final HomeWidgetDestination? destination = HomeWidgetLink.resolve(uri);

    if (destination == null) return;

    final BuildContext? context = ref
        .read(rootNavigatorKeyProvider)
        .currentContext;

    if (context == null || !context.mounted) return;

    switch (destination) {
      case HomeWidgetDestination.log:
        await NavigationUtils.toLog(context, ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      final StreamSubscription<Uri?> taps = ref
          .read(homeWidgetRepositoryProvider)
          .taps
          .listen((Uri? uri) => unawaited(_open(ref, uri)));

      // The other half: the tap that started the app, if it was one. Taken
      // once — reading it again would reopen the log flow on every resume.
      unawaited(
        ref
            .read(homeWidgetRepositoryProvider)
            .takeLaunchUri()
            .then((Uri? uri) => _open(ref, uri))
            // Swallowed on purpose: there is no screen of ours to report a
            // failed deep link on, and the user is already where they landed.
            // Logged, so "the widget did nothing" is answerable.
            .catchError((Object error, StackTrace stackTrace) {
              AppLogger.error(
                'Home widget launch tap failed',
                error: error,
                stackTrace: stackTrace,
              );
            }),
      );

      return taps.cancel;
    }, const <Object?>[]);

    return child;
  }
}
