/// Clock arithmetic and clock formatting, kept out of the widgets that show
/// it.
final class TimeOfDayUtils {
  /// "07:05" — zero-padded 24h.
  ///
  /// Deliberately not `TimeOfDay.format`, whose 12h/AM-PM output follows the
  /// locale: reminders are picked on a 24h wheel, and picking and reading
  /// must never disagree.
  static String hhmm(int hour, int minute) => '${_two(hour)}:${_two(minute)}';

  /// "HH:MM:SS" left until the next local midnight.
  ///
  /// Local, not UTC: the deal the dashboard counts down to ends at the end of
  /// the user's own day.
  static String untilMidnight(DateTime now) {
    final DateTime endOfDay = DateTime(now.year, now.month, now.day + 1);
    final Duration left = endOfDay.difference(now);

    return '${_two(left.inHours)}:${_two(left.inMinutes % 60)}:'
        '${_two(left.inSeconds % 60)}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
