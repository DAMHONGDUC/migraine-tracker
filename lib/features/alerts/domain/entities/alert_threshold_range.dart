/// The values `AlertsSettings.thresholdHpa` may take, and the only place that
/// decides them.
///
/// It used to be two copies of `3` and `10` — one on the threshold sheet, one
/// on the onboarding page — which is two chances for the picker a user starts
/// on and the picker they come back to to offer different numbers.
final class AlertThresholdRange {
  const AlertThresholdRange._();

  /// Below 2 hPa a 24h drop is ordinary weather almost everywhere, so the
  /// alert would fire on the dedupe window rather than on a front.
  static const double min = 2;

  /// 20 hPa in 24 hours is a deep storm. Past it the alert is one nobody
  /// would ever receive, which is a setting that only looks like a choice.
  static const double max = 20;

  /// The default a fresh install starts on, and what the server falls back to
  /// for a user whose doc carries no threshold.
  static const double initial = 5;

  /// What the app switches an account on at, by itself, the first time it
  /// qualifies (see `AlertsController.autoEnableOnce`). One under [initial] on
  /// purpose: a default nobody chose should catch the front slightly earlier
  /// than one the user dragged to, because the user who never opens the sheet
  /// is the one this exists for.
  static const double autoEnable = 4;

  /// Whole hPa only: the forecast is not precise enough for halves, and a
  /// slider that stops on 6.5 invites a confidence the data cannot pay.
  static int get divisions => (max - min).round();

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
