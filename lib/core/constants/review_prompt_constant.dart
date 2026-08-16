/// How often the store review prompt may be asked for, and what counts as a
/// moment worth asking after.
final class ReviewPromptConstant {
  /// How many times the app will ever ask, over the whole install.
  ///
  /// Three, because iOS caps `SKStoreReviewController` at three prompts per
  /// 365 days and silently drops the rest. Asking past the cap is not an
  /// error — it is a moment spent on a dialog that never appears, and the
  /// next real one is then wasted too.
  static const int maxAsks = 3;

  /// The floor between two asks.
  ///
  /// 120 days spreads [maxAsks] across a year rather than burning all three
  /// in the week a new user exports three reports.
  static const Duration minGapBetweenAsks = Duration(days: 120);

  /// How long after a pressure alert an attack still counts as that alert
  /// having been right.
  ///
  /// 24h, because that is the window the alert itself forecasts over (hard
  /// rule 7) — an attack after it is a different day's weather, not this
  /// alert coming true.
  static const Duration alertHitWindow = Duration(hours: 24);
}
