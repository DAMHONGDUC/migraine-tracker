import '../entities/app_update_config.dart';
import '../entities/installed_app_version.dart';
import 'version_utils.dart';

/// Decides whether this install must be blocked. Pure Dart, so every branch
/// is unit-tested — a bug here locks the entire install base out of an app
/// people reach for mid-migraine.
///
/// Order of comparison: **build name first, build number as the
/// tiebreaker.** The name is the release identity (`1.4.0`), so it decides;
/// the number only separates two builds of the same version, which is
/// exactly what it exists for on both stores.
///
/// It fails OPEN by design: only an explicit `enable_force_update` on a
/// build that is genuinely newer blocks anything. Anything unknown, missing
/// or unreadable lets the user in.
class ForceUpdateChecker {
  const ForceUpdateChecker();

  /// Non-null = block the app and point at that store link.
  ///
  /// [published] is this platform's section of the latest record, null when
  /// the record has none.
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

    // A readable name settles it outright, in both directions — a newer
    // name (TestFlight, a build already ahead) is never blocked.
    if (byName != null && byName != 0) {
      return byName < 0 ? published : null;
    }

    // Same version name, or a name we couldn't read: fall back to the
    // build number. 0 on either side means unknown — block nobody on a
    // comparison we can't make.
    if (installed.buildNumber <= 0 || published.buildNumber <= 0) return null;
    if (installed.buildNumber >= published.buildNumber) return null;

    return published;
  }
}
