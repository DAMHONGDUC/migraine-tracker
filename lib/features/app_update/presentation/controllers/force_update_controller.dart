import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:meta/meta.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/logging/crash_reporter.dart';
import '../../domain/entities/app_update_config.dart';
import '../../domain/entities/installed_app_version.dart';
import '../../domain/enums/app_platform.dart';
import '../../providers.dart';

@immutable
class ForceUpdateState {
  const ForceUpdateState({this.blockingUpdate});

  /// Non-null once the app must be blocked; it also carries the store link
  /// and the version to name in the sheet.
  final PlatformUpdateConfig? blockingUpdate;

  bool get isBlocking => blockingUpdate != null;
}

/// Owns the force-update decision. The wrapper widget only calls [check]
/// and renders what this exposes.
class ForceUpdateController extends Notifier<ForceUpdateState> {
  @override
  ForceUpdateState build() => const ForceUpdateState();

  /// Runs on every entry into the app (cold start and each resume).
  ///
  /// Fails open on ANY failure — offline, permission denied, plugin
  /// missing, malformed record. A backend hiccup must never stand between
  /// someone mid-migraine and the log button (hard rules 1 and 4).
  Future<void> check() async {
    if (state.isBlocking) return;

    try {
      final AppPlatform? platform = ref.read(currentAppPlatformProvider);

      if (platform == null) return;

      final InstalledAppVersion installed = await ref.read(
        installedAppVersionProvider.future,
      );
      final AppUpdateConfig? config = await ref
          .read(appUpdateRepositoryProvider)
          .latest();
      final PlatformUpdateConfig? blocking = ref
          .read(forceUpdateCheckerProvider)
          .blockingUpdate(
            published: config?.forPlatform(platform),
            installed: installed,
          );

      if (blocking == null) return;
      AppLogger.warning('Force update required', {
        'installed': '${installed.buildName}+${installed.buildNumber}',
        'published': '${blocking.buildName}+${blocking.buildNumber}',
      });
      state = ForceUpdateState(blockingUpdate: blocking);
    } catch (error, stackTrace) {
      // Swallowed on purpose: see the fail-open note above.
      AppLogger.warning('Force update check skipped', error);
      CrashReporter.recordError(
        error,
        stackTrace,
        reason: 'Force update check failed',
      );
    }
  }

  /// Sends the user to the store. False when the link could not be opened,
  /// so the sheet can say so instead of looking dead.
  Future<bool> openStore() async {
    final PlatformUpdateConfig? blocking = state.blockingUpdate;

    if (blocking == null) return false;
    AppLogger.action('Force update: open store');
    AppAnalytics.logForceUpdateCtaTapped();
    return ref.read(storeLauncherProvider).open(blocking.storeLink);
  }
}
