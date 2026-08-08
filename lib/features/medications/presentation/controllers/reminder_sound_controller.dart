import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/logging/app_logger.dart';
import '../../providers.dart';

/// Whether a medication reminder makes a sound when it fires.
///
/// On by default: a reminder that has to be noticed is the point of having
/// one, and someone who wants quiet says so.
///
/// The choice is per device, deliberately — it is about this phone being
/// audible right now (a night shift, a meeting), not about the account, and
/// so it is one of the few settings that does not sync.
class ReminderSoundController extends Notifier<bool> {
  static const String key = 'reminder_sound_enabled';

  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(key) ?? true;

  /// Persists the choice and re-lays every scheduled reminder with it.
  ///
  /// Rescheduling is not optional: the sound is baked into a notification
  /// when it is scheduled, so anything already queued would keep the old
  /// setting until it fired.
  Future<void> setEnabled(bool enabled) async {
    AppLogger.action('Toggle reminder sound', enabled);
    try {
      await ref.read(sharedPreferencesProvider).setBool(key, enabled);
      state = enabled;

      await ref.read(remindersControllerProvider).rescheduleAll();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Toggling reminder sound failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
