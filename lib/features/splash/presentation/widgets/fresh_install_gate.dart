import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../providers.dart';
import 'splash_dots.dart';

/// Holds the app back — under the same dots the splash route shows — until the
/// device check has finished.
///
/// **It has to sit above `_BaroEaseAppView`, not inside `MaterialApp`.** That
/// widget's first frame starts the sync write-through, records today's
/// pressure and reads `app_config`; the wipe behind this gate signs that
/// session out and drops the Firestore cache, and `clearPersistence` throws
/// `failed-precondition` once any of those has opened a stream.
///
/// **An error resolves to the app, never to an error screen.** The check
/// catches its own (`SdFreshInstall` never throws), so anything reaching here
/// is the launch itself failing — and an unchecked device is still the one in
/// the user's hand.
class FreshInstallGate extends ConsumerWidget {
  const FreshInstallGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(freshInstallProvider).isLoading ? const SplashDots() : child;
}
