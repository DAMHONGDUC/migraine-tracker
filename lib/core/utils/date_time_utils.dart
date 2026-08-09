/// Every piece of date and time arithmetic the app does, in one class.
///
/// One class on purpose rather than a `TimeOfDayUtils` beside a
/// `CalendarUtils` beside the axis helpers: date maths is where the same
/// mistake gets made twice, and it is only obvious that two call sites disagree
/// when they sit in the same file.
final class DateTimeUtils {
  /// "07:05" — zero-padded 24h.
  ///
  /// Deliberately not `TimeOfDay.format`, whose 12h/AM-PM output follows the
  /// locale: reminders are picked on a 24h wheel, and picking and reading must
  /// never disagree.
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

  /// First day of [date]'s month — the calendars move whole months at a time,
  /// so this is what a month is identified by.
  static DateTime monthOf(DateTime date) => DateTime(date.year, date.month);

  /// Last selectable day: the end of next year.
  ///
  /// Not "today": attacks are logged as they happen, and a calendar that stops
  /// at today cannot be scrolled forward to see there is nothing there.
  static DateTime lastSelectableDay(DateTime today) =>
      DateTime(today.year + 1, 12, 31);

  /// Hours from [from] to [to], fractional — the x axis a forecast is plotted
  /// on, where 0 is "now" and negatives are the past.
  static double hoursBetween(DateTime from, DateTime to) =>
      to.difference(from).inMinutes / 60;

  /// The instant an x of [hours] lands on. The inverse of [hoursBetween], so a
  /// tooltip names the time the point was actually plotted at.
  static DateTime timeAt(DateTime from, double hours) =>
      from.add(Duration(minutes: (hours * 60).round()));

  static String _two(int value) => value.toString().padLeft(2, '0');
}
