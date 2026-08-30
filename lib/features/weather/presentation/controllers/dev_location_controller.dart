import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/constants/prefs_key_constant.dart';
import '../../../../core/env/app_env.dart';
import '../../../../core/storage/secure_store.dart';
import '../../domain/enums/dev_location.dart';

/// Holds the dev-only faked position, and is the only thing that writes it.
class DevLocationController extends Notifier<DevLocation> {
  @override
  DevLocation build() {
    if (AppEnv.isProd) return DevLocation.off;

    return DevLocation.fromName(
      ref
          .watch(secureStoreProvider)
          .getString(PrefsKeyConstant.devFakeLocation),
    );
  }

  Future<void> set(DevLocation location) async {
    final SecureStore prefs = ref.read(secureStoreProvider);

    SdLogger.action(
      LogTagConstant.devLocation,
      'Dev fake location',
      location.name,
    );
    try {
      await prefs.setString(PrefsKeyConstant.devFakeLocation, location.name);
      state = location;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.devLocation,
        'Dev fake location failed',
        error: error,
        stackTrace: stackTrace,
        data: location.name,
      );
      rethrow;
    }
  }
}
