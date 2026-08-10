/// The durations the "how long did it last?" sheet offers.
///
/// Bands rather than a clock picker, because that is how the answer is
/// actually remembered — nobody recalls that an attack stopped at 14:37, but
/// everybody can say "about four hours".
final class AttackDurationConstant {
  /// Ends at 72h because that is the top of the 4–72h band a migraine is
  /// defined by; anything longer is a different clinical question and the
  /// user can say 72h and add a note.
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
