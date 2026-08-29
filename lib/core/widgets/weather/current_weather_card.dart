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
/// **It labels the reading with where it came from.** The name is a second,
/// slower read than the weather — the OS geocoder answers after the callable
/// does — so it is watched separately and simply appears when it lands; a
/// card that waited for both would show nothing for the length of the slower
/// one.
///
/// **It draws no pressure**, the same rule it carried on Insights — that
/// reading is the product and the dashboard's Today section already shows it
/// to the users who have paid. See [WeatherCardData.of].
///
/// **Without location permission it asks for it instead of failing.** The
/// unavailable line is the answer for offline and for a backend with no
/// credentials — states the user can do nothing about — and it was also what
/// someone who never granted location saw, which is a card saying the feature
/// is broken when it is one tap from working. See [_LocationPrompt].
class CurrentWeatherCard extends ConsumerWidget {
  const CurrentWeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Null while the status is still being read: the reading is what the card
    // is for, so it draws its own wait rather than flashing an ask that a
    // granted permission is about to replace.
    final AppPermissionStatus? permission = ref
        .watch(locationPermissionProvider)
        .value;

    // Asked BEFORE the report is watched, so a device with no position never
    // spends a callable round trip on a fetch that can only come back empty.
    if (permission != null && permission != AppPermissionStatus.granted) {
      return const _LocationPrompt();
    }

    final AsyncValue<WeatherReport?> async = ref.watch(weatherReportProvider);
    // Survives a refresh: AsyncValue keeps the last value while refetching.
    // The whole report, not just `current` — the detail screen draws the week
    // from it, and the headline falls back to today's high and low.
    final WeatherReport? report = async.value;
    // The app's language, not the device's — the name has to be written in
    // the language the rest of the card is.
    final String language = Localizations.localeOf(context).languageCode;

    return WeatherCard(
      title: context.l10n.weatherCardTitle,
      data: report == null ? null : WeatherCardData.of(report),
      // Null until it resolves, and null forever where the OS has no name for
      // the position — the card is complete without it either way.
      place: ref.watch(placeNameProvider(language)).value,
      // One state for offline, no permission and a backend with no WeatherKit
      // credentials — hard rule 4 makes them the same answer, so they must
      // not look like three different bugs.
      emptyLabel: context.l10n.weatherUnavailable,
      isLoading: async.isLoading,
    );
  }
}
