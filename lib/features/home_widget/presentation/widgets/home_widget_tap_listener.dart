import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/router/navigation_utils.dart';
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

  /// The only destination the widget offers today. A path rather than a bare
  /// scheme so a second button later is a second `case`, not a new listener.
  static const String logHost = 'log';

  Future<void> _open(WidgetRef ref, Uri? uri) async {
    if (uri == null || _target(uri) != logHost) return;

    final BuildContext? context = ref
        .read(rootNavigatorKeyProvider)
        .currentContext;

    if (context == null || !context.mounted) return;

    await NavigationUtils.toLog(context, ref);
  }

  /// WidgetKit hands back the `widgetURL` as written. `baroease://log` puts
  /// the word in the host, `baroease:///log` in the path, and which one turns
  /// up depends on the Swift side — read either rather than depend on it.
  String _target(Uri uri) =>
      uri.host.isNotEmpty ? uri.host : uri.pathSegments.firstOrNull ?? '';

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
            .catchError((Object _) {}),
      );

      return taps.cancel;
    }, const <Object?>[]);

    return child;
  }
}
