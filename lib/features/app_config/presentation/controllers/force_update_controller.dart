import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/logging/crash_reporter.dart';
import '../../domain/entities/app_config.dart';
import '../../domain/entities/app_update_config.dart';
import '../../domain/entities/installed_app_version.dart';
import '../../domain/enums/app_platform.dart';
import '../../domain/enums/force_update_decision.dart';
import '../../providers.dart';

@immutable
class ForceUpdateState {
  const ForceUpdateState({this.blockingUpdate});

  /// Non-null once the app must be blocked; it also carries the store link and the version to name in the sheet.
  final PlatformUpdateConfig? blockingUpdate;

  bool get isBlocking => blockingUpdate != null;
}

/// Owns the force-update decision. The wrapper widget only calls [check] and renders what this exposes.
///
/// **The record comes off `appConfigProvider`, not a read of its own.** It is
/// one field of the one document the app already listens to; a second `get`
/// was a second reader to keep pointing at the right document id and a second
/// thing to be denied on its own.
class ForceUpdateController extends Notifier<ForceUpdateState> {
  @override
  ForceUpdateState build() => const ForceUpdateState();

  /// Runs on every entry into the app (cold start and each resume).
  Future<void> check() async {
    if (state.isBlocking) return;

    try {
      final AppPlatform? platform = ref.read(currentAppPlatformProvider);

      if (platform == null) return;

      final InstalledAppVersion installed = await ref.read(
        installedAppVersionProvider.future,
      );
      // Awaited, not read: on a cold start the first snapshot has usually not
      // landed yet, and reading the current value there would answer
      // `AppConfig.empty` and let an unsupported build straight through. A
      // failed read resolves to `AppConfig.empty` on its own (the repository
      // emits it), so this cannot wait for good.
      final AppConfig config = await ref.read(appConfigProvider.future);
      final AppUpdateConfig? published = config.forceUpdate;
      final PlatformUpdateConfig? section = published?.forPlatform(platform);
      final ForceUpdateDecision decision = ref
          .read(forceUpdateCheckerProvider)
          .decide(published: section, installed: installed);

      // **The line that says why, and it is the whole point of this feature
      // being debuggable.** Six of the seven decisions are "carry on" and the
      // owner sets the switch by hand in the console, so without this a flag
      // at the wrong level, a section dropped for a missing store link and a
      // build that is simply not out of date all look identical: nothing
      // happens. Every input that fed the decision goes in beside it.
      SdLogger.info(LogTagConstant.appUpdate, 'Force update check', {
        'decision': decision.name,
        'platform': platform.name,
        'installed': '${installed.buildName}+${installed.buildNumber}',
        'publishedSection': section == null
            ? 'none'
            : '${section.buildName}+${section.buildNumber}',
        // Named separately from the section: a `true` here with a section that
        // is `none` means the flag was put beside `ios`/`android` rather than
        // inside one, which is the mistake this field exists to catch.
        'enableForceUpdate': section?.forceUpdateEnabled,
        'hasStoreLink': section?.storeLink.isNotEmpty,
        'platformsOnRecord': <String>[
          if (published?.ios != null) 'ios',
          if (published?.android != null) 'android',
        ].join(','),
      });

      if (!decision.isBlocking || section == null) return;
      SdLogger.warning(LogTagConstant.appUpdate, 'Force update required', {
        'installed': '${installed.buildName}+${installed.buildNumber}',
        'published': '${section.buildName}+${section.buildNumber}',
      });
      // Reported here rather than by the widget: the screen is a layer on a
      // watched provider now, so this line IS the moment it goes up — there is
      // no push that can be refused and no navigator that has to exist first.
      AppAnalytics.logForceUpdateShown();
      state = ForceUpdateState(blockingUpdate: section);
    } catch (error, stackTrace) {
      // Swallowed on purpose: see the fail-open note above.
      SdLogger.warning(
        LogTagConstant.appUpdate,
        'Force update check skipped',
        error,
      );
      CrashReporter.recordError(
        error,
        stackTrace,
        reason: 'Force update check failed',
      );
    }
  }

  /// Sends the user to the store. False when the link could not be opened, so the sheet can say so instead of looking dead.
  Future<bool> openStore() async {
    final PlatformUpdateConfig? blocking = state.blockingUpdate;

    if (blocking == null) return false;
    SdLogger.action(LogTagConstant.appUpdate, 'Force update: open store');
    AppAnalytics.logForceUpdateCtaTapped();
    return ref.read(storeLauncherProvider).open(blocking.storeLink);
  }
}
