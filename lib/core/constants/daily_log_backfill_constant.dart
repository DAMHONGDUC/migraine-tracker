import '../utils/date_time_utils.dart';

/// How far back a missed check-in may still be answered.
final class DailyLogBackfillConstant {
  /// Three days. A day lost to an attack is the one most worth having, and the
  /// morning after is when someone remembers it. Past three the answer is
  /// invention rather than memory, which is the reason the screen still has no
  /// date picker.
  static const int days = 3;

  /// The day a `yyyy-MM-dd` names, or today for a key that is missing, unreadable or outside the window.
  ///
  /// One owner, because three callers resolve it: the route, the dashboard's
  /// prompt and the reminder's payload.
  static DateTime resolve(String? dayKey) {
    final DateTime today = DateTime.now();

    if (dayKey == null) return today;

    final DateTime day;
    try {
      day = DateTimeUtils.dayFromKey(dayKey);
    } on FormatException {
      return today;
    }

    final int back = DateTimeUtils.dayFromKey(
      DateTimeUtils.dayKey(today),
    ).difference(day).inDays;

    return back >= 0 && back < days ? day : today;
  }
}
