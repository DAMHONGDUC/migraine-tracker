import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../features/weather/domain/entities/weather_report.dart';
import '../../../features/weather/domain/entities/weather_snapshot.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../extensions/context_extensions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_style.dart';
import '../../utils/signed_number_utils.dart';
import 'weather_attribution.dart';

part 'weather_card_condition.dart';
part 'weather_card_data.dart';
part 'weather_card_metrics.dart';

/// One weather card, drawn the same way wherever weather appears.
///
/// **In `core/` rather than in a feature, because two features draw it** —
/// the dashboard shows the conditions the user is in right now, and an
/// attack's detail screen shows the ones it was logged in. A widget one
/// feature owned would have to be imported from another's `presentation/`,
/// which the dependency rule forbids; this is the same answer
/// `core/widgets/sections/` already gives for a shared section.
///
/// **It draws, it does not fetch.** Both callers hand it a [WeatherCardData]
/// they built from their own source, so the card has no opinion on whether
/// the reading is live, hours old, or gated — see [CurrentWeatherCard] for
/// the live one.
///
/// **The Apple mark is the card's, not the caller's.** WeatherKit requires it
/// on every surface that renders its data and App Review checks for it, so it
/// is drawn here wherever there is data — a screen cannot forget it.
class WeatherCard extends StatelessWidget {
  const WeatherCard({
    required this.title,
    required this.data,
    required this.emptyLabel,
    this.isLoading = false,
    super.key,
  });

  final String title;

  /// Null, or empty, means there is nothing to draw and [emptyLabel] is shown
  /// instead.
  final WeatherCardData? data;

  /// What the card says with no data. The callers mean different things by it
  /// — "not fetched" against "never attached" — and one shared string would
  /// be wrong on one of them.
  final String emptyLabel;

  /// Only the live caller can be loading; a stored snapshot is already here
  /// or is not. A spinner rather than [emptyLabel] while the first fetch is
  /// in flight, because "unavailable" for the length of a round trip told
  /// every user the feature was broken.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final WeatherCardData? weather = data?.isEmpty ?? true ? null : data;

    return SdCardV2(
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: AppTextStyle.titleMedium),
            SizedBox(height: SdSpacingConstant.h12),
            if (weather != null) ...<Widget>[
              _Headline(data: weather),
              SizedBox(height: SdSpacingConstant.h16),
              _MetricGrid(metrics: _metrics(l10n, weather)),
              SizedBox(height: SdSpacingConstant.h12),
              const WeatherAttribution(),
            ] else if (isLoading)
              // Sized to roughly one headline, so the card does not jump a
              // grid's worth of height when the reading lands.
              SizedBox(
                height: SdSpacingConstant.h48,
                child: const Center(child: CircularProgressIndicator()),
              )
            else
              Text(emptyLabel, style: AppTextStyle.bodyMedium.secondary),
          ],
        ),
      ),
    );
  }
}

/// The reading in one line: the sky, the temperature, what it feels like.
///
/// **The glyph is drawn only where there is a condition to draw.** A stored
/// snapshot carries no condition code, and the "unknown" glyph beside a real
/// temperature reads as a failed load rather than as a reading Apple never
/// recorded.
class _Headline extends StatelessWidget {
  const _Headline({required this.data});

  final WeatherCardData data;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String? temperature = WeatherConditionUtils.temperature(
      l10n,
      data.temperatureCelsius,
    );
    final String? caption = _caption(l10n);

    // Neither half has anything to say — the metrics below still do.
    if (temperature == null && caption == null) return const SizedBox.shrink();

    return Row(
      children: <Widget>[
        if (data.condition != null) ...<Widget>[
          SdIconV2(
            icon: WeatherConditionUtils.icon(
              data.condition,
              daylight: data.daylight,
            ),
            size: SdSpacingConstant.r36,
            color: AppColors.primary,
          ),
          SizedBox(width: SdSpacingConstant.w12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (temperature != null)
                Text(
                  temperature,
                  style: AppTextStyle.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              // Two lines rather than an ellipsis: the condition and what it
              // feels like are both the point, and a Vietnamese pair of them
              // does not fit one line.
              if (caption != null)
                Text(
                  caption,
                  style: AppTextStyle.bodySmall.secondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// The condition word, and what it feels like when Apple said so.
  String? _caption(AppLocalizations l10n) {
    final String? label = WeatherConditionUtils.label(l10n, data.condition);
    final String? apparent = WeatherConditionUtils.temperature(
      l10n,
      data.apparentTemperatureCelsius,
    );

    if (apparent == null) return label;

    final String feels = l10n.weatherFeelsLike(apparent);

    return label == null ? feels : '$label · $feels';
  }
}
