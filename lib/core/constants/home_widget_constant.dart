/// Numbers and identifiers the home-screen widget runs by.
final class HomeWidgetConstant {
  /// The App Group both the app and the widget extension are members of.
  ///
  /// Hardcoded rather than read from `AppEnv`: the extension's entitlements
  /// file names the same string, and a value only one side could read is a
  /// value the two can silently disagree about.
  static const String appGroupId = 'group.app.dd.migraine.tracker';

  /// The WidgetKit timeline the app asks to reload after writing.
  static const String iOSWidgetName = 'BaroEaseWidget';

  /// How long a stored pressure reading stands for "now", measured from the
  /// local midnight of the day it belongs to.
  ///
  /// Two days, so today's reading is good today and tomorrow, yesterday's is
  /// good today, and anything older is not. A `DailyPressure` row is written
  /// at most once per local day, so a phone that spent a week offline still
  /// holds one — printing that as the current pressure would be a stale
  /// number wearing a live one's clothes. Past this the widget shows its
  /// no-reading dash instead.
  static const Duration pressureMaxAge = Duration(days: 2);

  /// Below this, a 24h change reads as steady rather than as a direction.
  ///
  /// Well under the 5 hPa alert default: the arrow says which way the needle
  /// is going, not that anything is worth acting on.
  static const double trendThresholdHpa = 1;
}
