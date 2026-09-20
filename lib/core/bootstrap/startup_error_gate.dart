import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../l10n/gen/app_localizations.dart';
import '../env/app_env.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_icon_constant.dart';
import 'app_bootstrap.dart';
import 'startup_failures_provider.dart';

/// Replaces the whole app when a startup step it cannot work without failed.
///
/// A layer in the tree rather than a route, for `BlockedAccountGate`'s reason:
/// it renders instead of `child`, so nothing underneath keeps running against
/// an SDK that is not there. It sits above force update and the block, both of
/// which read Firestore — asking a broken build to update is asking it to do
/// the thing that just failed.
///
/// **Only a genuinely broken build gets here.** `Firebase.initializeApp` is
/// local work: it does not fail on a bad connection, it fails when the build's
/// options and the bundled `GoogleService-Info.plist` disagree
/// (`[core/duplicate-app]`) or when there are no options at all. Logging an
/// attack offline, which hard rule 4 protects, never reaches this screen.
class StartupErrorGate extends ConsumerWidget {
  const StartupErrorGate({required this.child, super.key});

  /// The steps whose failure stops the app. One entry today; a second belongs
  /// here only if the app is equally useless without it.
  static const List<String> fatalSteps = <String>[AppBootstrap.firebaseStep];

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, String> failures = ref.watch(startupFailuresProvider);
    final String? detail = fatalSteps
        .map((String step) => failures[step])
        .nonNulls
        .firstOrNull;

    if (detail == null) return child;

    return StartupErrorView(detail: detail);
  }
}

/// The screen itself, in the app's words.
///
/// The look is [SdErrorViewV2]'s, so a second app of ours gets the same screen
/// without copying it. What stays here is what that package may not know: the
/// strings, the app's error glyph, and that a raw failure is for a tester
/// rather than for someone who downloaded this from the App Store.
class StartupErrorView extends StatelessWidget {
  const StartupErrorView({required this.detail, super.key});

  /// What the step threw.
  final String detail;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return SdErrorViewV2(
      icon: AppIconConstant.error,
      title: l10n.startupErrorTitle,
      message: l10n.startupErrorBody,
      // Outside production only: it names the bug for whoever can fix it, and
      // reads as noise to everyone else.
      detail: AppEnv.isProd ? null : detail,
    );
  }
}
