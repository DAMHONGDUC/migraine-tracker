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

  /// Whether two instants land on the same local calendar day.
  ///
  /// Local on both sides: a weather hour is stored UTC, and "is this today" is
  /// a question about the user's own day rather than Greenwich's.
  static bool isSameDay(DateTime first, DateTime second) {
    final DateTime a = first.toLocal();
    final DateTime b = second.toLocal();

    return a.year == b.year && a.month == b.month && a.day == b.day;
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

  /// A duration split into whole hours and the leftover minutes, so a call
  /// site can pick the ARB key that fits ("3h 20m", "3h", "20m") without
  /// doing the `% 60` itself. Days stay folded into the hours: a 3-day attack
  /// reads as 72h, which is the unit the 4–72h migraine band is stated in.
  static (int hours, int minutes) splitHm(Duration duration) => (
    duration.inHours,
    duration.inMinutes % 60,
  );

  /// The middle duration of [durations], or null when there are none.
  ///
  /// Median, never a mean: one 72-hour attack among a dozen short ones would
  /// drag an average somewhere no attack actually was, and the report states
  /// this as what a typical attack looks like.
  static Duration? median(List<Duration> durations) {
    if (durations.isEmpty) return null;
    final List<Duration> sorted = List<Duration>.of(durations)..sort();
    final int middle = sorted.length ~/ 2;

    if (sorted.length.isOdd) return sorted[middle];
    return Duration(
      microseconds:
          (sorted[middle - 1].inMicroseconds + sorted[middle].inMicroseconds) ~/
          2,
    );
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
