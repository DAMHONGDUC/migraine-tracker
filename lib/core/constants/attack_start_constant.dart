/// How far back the "when did it start?" sheet offers to move an attack.
final class AttackStartConstant {
  /// Stops at 48h. The weather backfill reaches seven days, but memory does not:
  /// past two days the hour is a guess, and a guessed hour pulls a real pressure
  /// reading onto it — which is the failure this sheet exists to prevent.
  static const List<Duration> agoOptions = <Duration>[
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 4),
    Duration(hours: 6),
    Duration(hours: 8),
    Duration(hours: 12),
    Duration(hours: 24),
    Duration(hours: 36),
    Duration(hours: 48),
  ];
}
