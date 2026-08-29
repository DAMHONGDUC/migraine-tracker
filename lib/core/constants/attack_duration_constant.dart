/// The durations the "how long did it last?" sheet offers.
final class AttackDurationConstant {
  /// Ends at 72h because that is the top of the 4–72h band a migraine is defined by; anything longer is a different clinical question and the user can.
  static const List<Duration> options = <Duration>[
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 4),
    Duration(hours: 6),
    Duration(hours: 8),
    Duration(hours: 12),
    Duration(hours: 24),
    Duration(hours: 48),
    Duration(hours: 72),
  ];
}
