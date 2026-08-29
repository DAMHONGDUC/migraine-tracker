import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'data/repositories/firestore_app_update_repository.dart';
import 'data/services/url_store_launcher.dart';
import 'domain/entities/installed_app_version.dart';
import 'domain/enums/app_platform.dart';
import 'domain/repositories/app_update_repository.dart';
import 'domain/services/force_update_checker.dart';
import 'domain/services/store_launcher.dart';
import 'presentation/controllers/force_update_controller.dart';

final appUpdateRepositoryProvider = Provider<AppUpdateRepository>(
  (ref) => FirestoreAppUpdateRepository(FirebaseFirestore.instance),
);

final forceUpdateCheckerProvider = Provider<ForceUpdateChecker>(
  (ref) => const ForceUpdateChecker(),
);

final storeLauncherProvider = Provider<StoreLauncher>(
  (ref) => const UrlStoreLauncher(),
);

/// Null anywhere the update record has no section for (desktop, web) — nothing to compare, nothing to block.
final currentAppPlatformProvider = Provider<AppPlatform?>(
  (ref) => switch (defaultTargetPlatform) {
    TargetPlatform.android => AppPlatform.android,
    TargetPlatform.iOS => AppPlatform.ios,
    _ => null,
  },
);

/// Build number 0 when it can't be parsed — the checker reads that as "unknown" and blocks nobody.
final installedAppVersionProvider = FutureProvider<InstalledAppVersion>((
  ref,
) async {
  final PackageInfo info = await PackageInfo.fromPlatform();

  return InstalledAppVersion(
    buildName: info.version,
    buildNumber: int.tryParse(info.buildNumber) ?? 0,
  );
});

final forceUpdateControllerProvider =
    NotifierProvider<ForceUpdateController, ForceUpdateState>(
      ForceUpdateController.new,
    );
