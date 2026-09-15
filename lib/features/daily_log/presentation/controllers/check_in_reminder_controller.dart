import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/constants/prefs_key_constant.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/storage/secure_store.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/locale_utils.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../notifications/domain/services/notification_scheduler.dart';
import '../../../notifications/providers.dart';
import '../../providers.dart';

/// The evening nudge's two settings.
@immutable
class CheckInReminderSettings {
  const CheckInReminderSettings({
    required this.enabled,
    required this.minuteOfDay,
  });

  /// 20:30 by default — late enough that the day is over, early enough to be read before bed.
  static const int defaultMinuteOfDay = 20 * 60 + 30;

  final bool enabled;

  /// Local time of day as minutes past midnight, the same unit `MedicationReminder` stores.
  final int minuteOfDay;

  int get hour => minuteOfDay ~/ 60;
  int get minute => minuteOfDay % 60;
}

/// Owns the daily check-in nudge: its switch, its time, and the one next notification it keeps armed.
///
/// **It is not a medication reminder and does not spend that budget.**
/// `MedicationReminder.freeLimit` caps reminders for drugs; this one asks the
/// user about their day, which is the app's own control group
/// (`lib/features/daily_log/CLAUDE.md`).
///
/// **One occurrence at a time, never a daily repeat.** A repeat would fire on a
/// day already answered, so the next one is armed after every check-in and on
/// every resume — the nudge exists only while the day it asks about is open.
class CheckInReminderController extends Notifier<CheckInReminderSettings> {
  @override
  CheckInReminderSettings build() {
    final SecureStore prefs = ref.watch(secureStoreProvider);

    return CheckInReminderSettings(
      // Off until asked for: a notification nobody agreed to is the fastest way to have notifications turned off wholesale.
      enabled: prefs.getBool(PrefsKeyConstant.checkInReminderEnabled) ?? false,
      minuteOfDay:
          prefs.getInt(PrefsKeyConstant.checkInReminderMinute) ??
          CheckInReminderSettings.defaultMinuteOfDay,
    );
  }

  /// The Settings switch. Asks the OS only when turning it on, and only after the app's own switch has been flipped.
  Future<bool> setEnabled(bool enabled) async {
    final NotificationScheduler scheduler = ref.read(
      notificationSchedulerProvider,
    );

    try {
      if (enabled && !await scheduler.ensurePermission()) {
        SdLogger.info(
          LogTagConstant.dailyLog,
          'Check-in reminder refused by the OS',
        );

        return false;
      }

      await ref
          .read(secureStoreProvider)
          .setBool(PrefsKeyConstant.checkInReminderEnabled, enabled);
      state = CheckInReminderSettings(
        enabled: enabled,
        minuteOfDay: state.minuteOfDay,
      );
      SdLogger.action(
        LogTagConstant.dailyLog,
        'Check-in reminder',
        <String, Object?>{'enabled': enabled, 'minuteOfDay': state.minuteOfDay},
      );
      await reschedule();

      return enabled;
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.dailyLog,
        'Check-in reminder toggle failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> setTime(int minuteOfDay) async {
    try {
      await ref
          .read(secureStoreProvider)
          .setInt(PrefsKeyConstant.checkInReminderMinute, minuteOfDay);
      state = CheckInReminderSettings(
        enabled: state.enabled,
        minuteOfDay: minuteOfDay,
      );
      SdLogger.action(
        LogTagConstant.dailyLog,
        'Check-in reminder time',
        minuteOfDay,
      );
      await reschedule();
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.dailyLog,
        'Check-in reminder time failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Arms the next nudge, or takes the armed one down.
  ///
  /// Called on launch, on resume and after every check-in — best-effort, like
  /// every other side errand off the log flow (hard rule 4): a scheduler that
  /// will not answer costs a notification, never the save that asked for it.
  Future<void> reschedule() async {
    final NotificationScheduler scheduler = ref.read(
      notificationSchedulerProvider,
    );

    try {
      if (!state.enabled) {
        await scheduler.cancelCheckIn();

        return;
      }

      final DateTime when = await _nextOccurrence();
      final AppLocalizations l10n = lookupAppLocalizations(
        LocaleUtils.resolve(
          chosen: ref.read(localeControllerProvider),
          platform: PlatformDispatcher.instance.locale,
          supported: AppLocalizations.supportedLocales,
        ),
      );

      await scheduler.scheduleCheckIn(
        when: when,
        title: l10n.checkInReminderTitle,
        body: l10n.checkInReminderBody,
      );
      SdLogger.info(
        LogTagConstant.dailyLog,
        'Check-in reminder armed',
        when.toIso8601String(),
      );
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.dailyLog,
        'Arming the check-in reminder failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Today at the chosen time while today is unanswered and that time has not passed; tomorrow otherwise.
  Future<DateTime> _nextOccurrence() async {
    final DateTime now = DateTime.now();
    final DateTime todayAt = DateTime(
      now.year,
      now.month,
      now.day,
      state.hour,
      state.minute,
    );
    final bool answered =
        (await ref.read(dailyLogRepositoryProvider).forDay(now))?.isAnswered ??
        false;

    if (!answered && todayAt.isAfter(now)) return todayAt;

    return todayAt.add(const Duration(days: 1));
  }

  /// The day the nudge is asking about, for the screen it opens.
  String get dayKey => DateTimeUtils.dayKey(DateTime.now());
}
