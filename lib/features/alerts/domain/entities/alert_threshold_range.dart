/// The values `AlertsSettings.thresholdHpa` may take, and the only place that
/// decides them.
///
/// It used to be two copies of `3` and `10` — one on the threshold sheet, one
/// on the onboarding page — which is two chances for the picker a user starts
/// on and the picker they come back to to offer different numbers.
final class AlertThresholdRange {
  const AlertThresholdRange._();

  /// The absolute floor. Below 2 hPa a 24h drop is ordinary weather almost
  /// everywhere, so the alert would fire on the dedupe window rather than on
  /// a front.
  ///
  /// The threshold sheet lets the user pick a narrower *window* inside
  /// [min]-[max] to drag within; these two are the walls that window may not
  /// pass, not the ends of the slider.
  static const double min = 2;

  /// The absolute ceiling. 20 hPa in 24 hours is a deep storm; past it the
  /// alert is one nobody would ever receive, which is a setting that only
  /// looks like a choice.
  static const double max = 20;

  /// The default a fresh install starts on, and what the server falls back to
  /// for a user whose doc carries no threshold.
  static const double initial = 5;

  /// Whole hPa only: the forecast is not precise enough for halves, and a
  /// slider that stops on 6.5 invites a confidence the data cannot pay. Pass
  /// a narrower window's ends to get its own stop count.
  static int divisionsBetween(double from, double to) => (to - from).round();

  /// The stops across the whole allowed range.
  static int get divisions => divisionsBetween(min, max);

  static bool contains(num value) => value >= min && value <= max;

  /// The typed value, or null when the text is not a whole number inside the
  /// range. Null is the error state — the caller shows the message and
  /// refuses the commit.
  static double? parse(String input) {
    final int? value = int.tryParse(input.trim());

    if (value == null) return null;

    return contains(value) ? value.toDouble() : null;
  }

  /// Pulls a stored value onto the slider. A threshold written under a
  /// different range would otherwise be handed to `Slider` outside its
  /// bounds, which throws rather than degrading.
  static double clamp(double value) => value.clamp(min, max);
}
