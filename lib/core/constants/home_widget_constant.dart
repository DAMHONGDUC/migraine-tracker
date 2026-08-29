/// Numbers and identifiers the home-screen widget runs by.
final class HomeWidgetConstant {
  /// The App Group both the app and the widget extension are members of.
  static const String appGroupId = 'group.app.dd.migraine.tracker';

  /// The WidgetKit timeline the app asks to reload after writing.
  static const String iOSWidgetName = 'BaroEaseWidget';

  /// How long a stored pressure reading stands for "now", measured from the local midnight of the day it belongs to.
  static const Duration pressureMaxAge = Duration(days: 2);

  /// Below this, a 24h change reads as steady rather than as a direction.
  static const double trendThresholdHpa = 1;
}
