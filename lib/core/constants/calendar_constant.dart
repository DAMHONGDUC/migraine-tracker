/// Fixed edges of the app's two calendars.
final class CalendarConstant {
  /// Six rows always, so navigating months never changes the sheet's height.
  static const int weekRows = 6;
  static const int daysPerWeek = 7;

  /// Oldest day History's calendar will scroll back to. Well before the app existed, so an imported or back-dated history always fits.
  static final DateTime historyFirstDay = DateTime(2020);

  /// Oldest day the export date filter offers. Later than [historyFirstDay] on purpose: an export cannot predate the app.
  static final DateTime exportFilterFirstDay = DateTime(2025);
}
