import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/constants/prefs_key_constant.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/logging/app_logger.dart';

/// The seed behind the dev-only fake HealthKit, or null when it is off.
///
/// A number rather than a bool: it both switches the fake on AND decides
/// which history it generates, so reseeding produces a different one while a
/// restart reproduces the same.
class DevHealthSeedController extends Notifier<int?> {
  @override
  int? build() =>
      ref.watch(sharedPreferencesProvider).getInt(PrefsKeyConstant.devHealthSeed);

  Future<void> set(int seed) async {
    await ref
        .read(sharedPreferencesProvider)
        .setInt(PrefsKeyConstant.devHealthSeed, seed);
    AppLogger.action('Dev health seed set', seed);
    state = seed;
  }

  Future<void> clear() async {
    await ref
        .read(sharedPreferencesProvider)
        .remove(PrefsKeyConstant.devHealthSeed);
    AppLogger.action('Dev health seed cleared');
    state = null;
  }
}
