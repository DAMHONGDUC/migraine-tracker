import '../entities/next_reminder.dart';
import '../repositories/medication_reminder_repository.dart';

/// Picks the soonest enabled daily reminder relative to "now". Pure Dart —
/// each reminder repeats daily at its [minuteOfDay], so its next occurrence is
/// today at that time if still ahead, otherwise the same time tomorrow.
class NextReminderCalculator {
  const NextReminderCalculator();

  NextReminder? compute(
    List<MedicationReminderView> views, {
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    MedicationReminderView? best;
    Duration? bestDelay;

    for (final view in views) {
      final reminder = view.reminder;
      if (!reminder.enabled) continue;
      var next = today.add(Duration(minutes: reminder.minuteOfDay));
      if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
      final delay = next.difference(now);
      if (bestDelay == null || delay < bestDelay) {
        bestDelay = delay;
        best = view;
      }
    }

    if (best == null) return null;
    return NextReminder(
      medicationId: best.reminder.medicationId,
      medicationName: best.medicationName,
      minuteOfDay: best.reminder.minuteOfDay,
      timeUntil: bestDelay!,
    );
  }
}
