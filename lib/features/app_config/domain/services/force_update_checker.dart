import '../entities/app_update_config.dart';
import '../entities/installed_app_version.dart';
import '../enums/force_update_decision.dart';
import 'version_utils.dart';

/// Decides whether this install must be blocked.
class ForceUpdateChecker {
  const ForceUpdateChecker();

  /// Non-null = block the app and point at that store link. [published] is this platform's section of the latest record, null when the record has none.
  PlatformUpdateConfig? blockingUpdate({
    required PlatformUpdateConfig? published,
    required InstalledAppVersion installed,
  }) =>
      decide(published: published, installed: installed).isBlocking
      ? published
      : null;

  /// The same decision, with the reason for it.
  ///
  /// **Every `return` here names itself**, because the owner sets this switch
  /// by hand in the Firebase console and six of the seven answers are "carry
  /// on". Told apart in the log, "the flag is off" and "your build is already
  /// current" are two different things to go and fix; told as nothing at all
  /// they are both "force update is broken".
  ForceUpdateDecision decide({
    required PlatformUpdateConfig? published,
    required InstalledAppVersion installed,
  }) {
    if (published == null) return ForceUpdateDecision.noPublishedBuild;
    if (!published.forceUpdateEnabled) return ForceUpdateDecision.notEnabled;
    if (published.storeLink.isEmpty) return ForceUpdateDecision.noStoreLink;

    final int? byName = VersionUtils.compare(
      installed.buildName,
      published.buildName,
    );

    // A readable name settles it outright, in both directions — a newer name is never blocked.
    if (byName != null && byName != 0) {
      return byName < 0
          ? ForceUpdateDecision.blocked
          : ForceUpdateDecision.installedIsNewer;
    }

    // - Same version name, or unreadable name: fall back to the build number. - 0 on either side means unknown — block nobody on a comparison we can't make.
    if (installed.buildNumber <= 0 || published.buildNumber <= 0) {
      return ForceUpdateDecision.buildNumberUnknown;
    }
    if (installed.buildNumber >= published.buildNumber) {
      return ForceUpdateDecision.upToDate;
    }

    return ForceUpdateDecision.blocked;
  }
}
