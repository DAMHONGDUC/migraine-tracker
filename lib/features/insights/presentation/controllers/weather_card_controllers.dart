import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/enums/weather_metric.dart';

/// Which reading the weather card's hourly row is showing.
///
/// A Notifier rather than local widget state so the pick survives the card
/// rebuilding — the report refetches on pull-to-refresh, and a dropdown that
/// snapped back to "Conditions" every time would read as a bug.
class WeatherMetricController extends Notifier<WeatherMetric> {
  @override
  WeatherMetric build() => WeatherMetric.conditions;

  void set(WeatherMetric metric) => state = metric;
}

/// Which day of the card's week is selected, 0 being today.
///
/// An index rather than a date: the week slides forward at midnight, and an
/// index keeps "the day I picked" meaning the same position rather than a
/// date that may have fallen off the start of the strip.
class WeatherDayController extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) => state = index;
}
