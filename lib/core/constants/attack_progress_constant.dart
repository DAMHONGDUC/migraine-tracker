/// What still counts as an attack that is happening now.
final class AttackProgressConstant {
  /// How long after it started an unfinished attack is still treated as running. 72h is the top of the 4–72h band a migraine is defined by, so past it the blank end time is an unanswered question rather than an attack in progress.
  static const Duration window = Duration(hours: 72);

  /// How often the running timer redraws. One second, because the timer is the screen's whole content and a minute-granular one looks broken.
  static const Duration tick = Duration(seconds: 1);
}
