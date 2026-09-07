import '../entities/app_update_config.dart';
import '../entities/installed_app_version.dart';
import 'version_utils.dart';

/// Decides whether this install must be blocked.
class ForceUpdateChecker {
  const ForceUpdateChecker();

  /// Non-null = block the app and point at that store link. [published] is this platform's section of the latest record, null when the record has none.
  PlatformUpdateConfig? blockingUpdate({
    required PlatformUpdateConfig? published,
    required InstalledAppVersion installed,
  }) {
    if (published == null) return null;
    if (!published.forceUpdateEnabled) return null;
    if (published.storeLink.isEmpty) return null;

    final int? byName = VersionUtils.compare(
      installed.buildName,
      published.buildName,
    );

    // A readable name settles it outright, in both directions — a newer name is never blocked.
    if (byName != null && byName != 0) {
      return byName < 0 ? published : null;
    }

    // - Same version name, or unreadable name: fall back to the build number. - 0 on either side means unknown — block nobody on a comparison we can't make.
    if (installed.buildNumber <= 0 || published.buildNumber <= 0) return null;
    if (installed.buildNumber >= published.buildNumber) return null;

    return published;
  }
}
