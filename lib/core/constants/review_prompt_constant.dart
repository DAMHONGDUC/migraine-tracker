/// How often the store review prompt may be asked for, and what counts as a moment worth asking after.
final class ReviewPromptConstant {
  /// How many times the app will ever ask, over the whole install.
  static const int maxAsks = 3;

  /// The floor between two asks. 120 days spreads [maxAsks] across a year rather than burning all three in the week a new user exports three reports.
  static const Duration minGapBetweenAsks = Duration(days: 120);

  /// How long after a pressure alert an attack still counts as that alert having been right.
  static const Duration alertHitWindow = Duration(hours: 24);
}
