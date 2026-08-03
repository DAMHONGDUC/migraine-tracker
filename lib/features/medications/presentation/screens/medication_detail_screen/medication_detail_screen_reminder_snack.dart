part of 'medication_detail_screen.dart';

/// Confirms a just-saved reminder, spelling out when it will next fire.
final class _ReminderSnack {
  /// The "tomorrow" case matters most: a time already past today rolls to the
  /// next day (see [LocalNotificationScheduler]), which otherwise reads as
  /// "nothing happened". Mirrors that scheduler's boundary (a time == now
  /// counts as past).
  static void show(BuildContext context, int minuteOfDay) {
    final AppLocalizations l10n = context.l10n;
    final DateTime now = DateTime.now();
    final DateTime todayAt = DateTime(
      now.year,
      now.month,
      now.day,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
    final bool firesTomorrow = !todayAt.isAfter(now);
    final String time =
        '${(minuteOfDay ~/ 60).toString().padLeft(2, '0')}:'
        '${(minuteOfDay % 60).toString().padLeft(2, '0')}';
    final String message = firesTomorrow
        ? l10n.remindersScheduledTomorrow(time)
        : l10n.remindersScheduledToday(time);

    SdSnackBarUtilsV2.success(context, message);
  }
}
