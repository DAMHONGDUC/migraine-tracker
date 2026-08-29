/// How far back a health chart looks — the D / W / M / 6M selector Apple Health itself uses, and the one the step and sleep cards share.
enum HealthRange {
  day,
  week,
  month,
  halfYear;

  /// Calendar days the window covers, counting today.
  int get days => switch (this) {
    HealthRange.day => 1,
    HealthRange.week => 7,
    HealthRange.month => 30,
    HealthRange.halfYear => 182,
  };

  /// Whether the chart groups its days into weeks.
  bool get isWeekly => this == HealthRange.halfYear;
}
