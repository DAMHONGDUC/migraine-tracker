import 'package:meta/meta.dart';

import '../enums/app_platform.dart';

/// One platform's section of an update record.
@immutable
class PlatformUpdateConfig {
  const PlatformUpdateConfig({
    required this.storeLink,
    required this.buildName,
    required this.buildNumber,
    required this.forceUpdateEnabled,
  });

  /// Where "Update now" sends the user — the App Store / Play listing.
  final String storeLink;

  /// Marketing version of the published build (`1.4.0`). Display only.
  final String buildName;

  /// The gate. Both stores require it to increase with every upload, so it
  /// is the one value worth comparing — no semver parsing, no ambiguity.
  final int buildNumber;

  /// Off means "a new build exists, but don't block anyone".
  final bool forceUpdateEnabled;
}

/// One record of the public `app_updates` collection: the currently
/// published build per platform, plus when the record was created.
@immutable
class AppUpdateConfig {
  const AppUpdateConfig({required this.createdAt, this.android, this.ios});

  /// `create_date` — what "the latest record" is ordered by.
  final DateTime createdAt;

  /// Null when the record has no section for that platform (or it was
  /// malformed): nothing to compare against, so nothing gets blocked.
  final PlatformUpdateConfig? android;
  final PlatformUpdateConfig? ios;

  PlatformUpdateConfig? forPlatform(AppPlatform platform) => switch (platform) {
    AppPlatform.android => android,
    AppPlatform.ios => ios,
  };
}
