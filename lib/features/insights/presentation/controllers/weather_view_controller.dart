import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/enums/weather_view.dart';

/// Which face of the weather card is showing.
///
/// A Notifier rather than local widget state so the pick survives the card
/// rebuilding — the report refetches on refresh, and a segmented control that
/// snapped back to "Hourly" every time would read as a bug.
class WeatherViewController extends Notifier<WeatherView> {
  @override
  WeatherView build() => WeatherView.hourly;

  void set(WeatherView view) => state = view;
}
