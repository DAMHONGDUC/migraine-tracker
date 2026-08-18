import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/weather/domain/entities/weather_report.dart';
import '../../../features/weather/providers.dart';
import '../../extensions/context_extensions.dart';
import 'weather_card.dart';

/// The weather the user is standing in, at the position the device reports.
///
/// **The dashboard's card, and the app's only live weather surface** — it
/// replaced the Insights weather tab, whose day strip and hourly chart were
/// a screen's worth of forecast on a screen nobody opened for one.
///
/// **Placed unconditionally, empty state and all.** Every other dashboard
/// section is asked about before it is placed, because the list inserts a gap
/// between entries; this one always has something to say instead — a spinner
/// while the first fetch is in flight, and one line when there is no reading.
/// A card that vanished would leave a user who denied location permission
/// with no sign the feature exists at all.
///
/// **It draws no pressure**, the same rule it carried on Insights — that
/// reading is the product and the dashboard's Today section already shows it
/// to the users who have paid. See [WeatherCardData.of].
class CurrentWeatherCard extends ConsumerWidget {
  const CurrentWeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<WeatherReport?> async = ref.watch(weatherReportProvider);
    // Survives a refresh: AsyncValue keeps the last value while refetching,
    // so a reload redraws the reading it already had rather than blanking.
    final WeatherConditions? now = async.value?.current;

    return WeatherCard(
      title: context.l10n.weatherCardTitle,
      data: now == null ? null : WeatherCardData.of(now),
      // One state for offline, no permission and a backend with no WeatherKit
      // credentials — hard rule 4 makes them the same answer, so they must
      // not look like three different bugs.
      emptyLabel: context.l10n.weatherUnavailable,
      isLoading: async.isLoading,
    );
  }
}
