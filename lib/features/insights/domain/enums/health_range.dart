/// How far back a health chart looks — the D / W / M / 6M selector Apple
/// Health itself uses, and the one the step and sleep cards share.
enum HealthRange {
  day,
  week,
  month,
  halfYear;

  /// Calendar days the window covers, counting today.
  ///
  /// A month is 30 and half a year is 182 rather than real calendar
  /// arithmetic: the window is a rolling one, not "since the 1st", so a
  /// fixed length is what keeps the bar count stable as the month changes
  /// under it.
  int get days => switch (this) {
    HealthRange.day => 1,
    HealthRange.week => 7,
    HealthRange.month => 30,
    HealthRange.halfYear => 182,
  };

  /// Whether the chart groups its days into weeks.
  ///
  /// Only half a year does. 182 bars on a card ~350pt wide is under 2pt each
  /// — a texture rather than a chart — so those become ~26 weekly totals.
  bool get isWeekly => this == HealthRange.halfYear;
}
