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

  /// Marketing version of the published build (`1.4.0`). **Compared first**, and it settles the decision in both directions when both sides parse — see `ForceUpdateChecker`. Shown on the sheet as well.
  final String buildName;

  /// The fallback comparison: same name on both sides, or a name neither side can parse. Both stores require it to increase with every upload.
  final int buildNumber;

  /// Off means "a new build exists, but don't block anyone".
  final bool forceUpdateEnabled;
}

/// The `force_update` section of `app_config/current`: the currently published build per platform.
@immutable
class AppUpdateConfig {
  const AppUpdateConfig({this.android, this.ios});

  /// Null when the record has no section for that platform (or it was malformed): nothing to compare against, so nothing gets blocked.
  final PlatformUpdateConfig? android;
  final PlatformUpdateConfig? ios;

  PlatformUpdateConfig? forPlatform(AppPlatform platform) => switch (platform) {
    AppPlatform.android => android,
    AppPlatform.ios => ios,
  };
}
