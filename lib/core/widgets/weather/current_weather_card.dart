import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../features/weather/domain/entities/weather_report.dart';
import '../../../features/weather/providers.dart';
import '../../constants/log_tag_constant.dart';
import '../../extensions/context_extensions.dart';
import '../../permissions/app_permission.dart';
import '../../theme/app_icon_constant.dart';
import '../../theme/app_icon_size.dart';
import '../../theme/app_text_style.dart';
import 'weather_card.dart';

part 'current_weather_card_location.dart';

/// The weather the user is standing in, at the position the device reports.
class CurrentWeatherCard extends ConsumerWidget {
  const CurrentWeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Null while the status is still being read.
    final AppPermissionStatus? permission = ref
        .watch(locationPermissionProvider)
        .value;

    // Asked BEFORE the report is watched, so a device with no position never spends a callable round trip on a fetch that can only come back empty.
    if (permission != null && permission != AppPermissionStatus.granted) {
      return const _LocationPrompt();
    }

    final AsyncValue<WeatherReport?> async = ref.watch(weatherReportProvider);
    // Survives a refresh: AsyncValue keeps the last value while refetching.
    final WeatherReport? report = async.value;
    // The app's language, not the device's — the name has to be written in the language the rest of the card is.
    final String language = Localizations.localeOf(context).languageCode;

    return WeatherCard(
      title: context.l10n.weatherCardTitle,
      data: report == null ? null : WeatherCardData.of(report),
      // Null until it resolves, and null forever where the OS has no name for the position — the card is complete without it either way.
      place: ref.watch(placeNameProvider(language)).value,
      // One state for offline, no permission and a backend with no WeatherKit credentials.
      emptyLabel: context.l10n.weatherUnavailable,
      isLoading: async.isLoading,
    );
  }
}
