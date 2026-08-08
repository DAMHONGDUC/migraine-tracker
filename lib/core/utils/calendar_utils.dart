/// Month arithmetic the calendars navigate by.
final class CalendarUtils {
  /// First day of [date]'s month — the calendars move whole months at a time,
  /// so this is what a month is identified by.
  static DateTime monthOf(DateTime date) => DateTime(date.year, date.month);

  /// Last selectable day: the end of next year.
  ///
  /// Not "today": attacks are logged as they happen, and a calendar that
  /// stops at today cannot be scrolled forward to see there is nothing there.
  static DateTime lastSelectableDay(DateTime today) =>
      DateTime(today.year + 1, 12, 31);
}
