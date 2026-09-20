import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../l10n/gen/app_localizations.dart';
import '../env/app_env.dart';
import '../env/flavor_config_mismatch.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_icon_constant.dart';
import 'startup_failures_provider.dart';

/// Replaces the whole app when a startup step it cannot work without failed.
///
/// A layer in the tree rather than a route, for `BlockedAccountGate`'s reason:
/// it renders instead of `child`, so nothing underneath keeps running against
/// an SDK that is not there. It sits above force update and the block, both of
/// which read Firestore — asking a broken build to update is asking it to do
/// the thing that just failed.
///
/// **Only a genuinely broken build gets here**, and the failure's *type* is
/// what says so — not which step it came from. See [isFatal].
class StartupErrorGate extends ConsumerWidget {
  const StartupErrorGate({required this.child, super.key});

  /// Whether a startup failure is one the app must refuse to run past.
  ///
  /// **A mismatch, never an absence.** The rule used to be "the Firebase step
  /// failed", which caught the wrong three quarters of the cases: that step
  /// also fails with `[core/no-app]` on a build carrying no config at all and
  /// with `[core/duplicate-app]` on a hot restart, and neither is a reason to
  /// take the app away from its user. Data here is local-first, so an app
  /// whose backend never came up still logs an attack — hard rule 4 — and a
  /// fresh clone with nothing configured yet must still run.
  ///
  /// What cannot be allowed to continue is a build writing into the *other*
  /// environment's project, because that one works perfectly: nothing is
  /// broken on screen, and the damage is real rows in the wrong database.
  static bool isFatal(Object error) => error is FlavorConfigMismatch;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, Object> failures = ref.watch(startupFailuresProvider);
    final Object? fatal = failures.values.where(isFatal).firstOrNull;

    if (fatal == null) return child;

    return StartupErrorView(detail: '$fatal');
  }
}

/// The screen itself, in the app's words.
///
/// The look is [SdErrorViewV2]'s, so a second app of ours gets the same screen
/// without copying it. What stays here is what that package may not know: the
/// strings, the app's error glyph, and that a raw failure is for a tester
/// rather than for someone who downloaded this from the App Store.
class StartupErrorView extends StatelessWidget {
  const StartupErrorView({
    required this.detail,
    this.showDetail = !AppEnv.isProd,
    super.key,
  });

  /// What the step threw.
  final String detail;

  /// Whether [detail] is on screen. A const by default, so the release binary
  /// does not carry the raw failure at all; a parameter so the release
  /// behaviour is testable from a dev test run.
  final bool showDetail;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return SdErrorViewV2(
      icon: AppIconConstant.error,
      title: l10n.startupErrorTitle,
      message: l10n.startupErrorBody,
      // Outside production only: it names the bug for whoever can fix it, and
      // reads as noise to everyone else.
      detail: showDetail ? detail : null,
    );
  }
}
