import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/utils/chart_axis_utils.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/weather_attribution.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../weather/domain/entities/weather_report.dart';
import '../../../weather/providers.dart';
import '../../domain/enums/weather_metric.dart';
import '../../providers.dart';

part 'weather_card_condition.dart';
part 'weather_card_day_strip.dart';
part 'weather_card_metric.dart';
part 'weather_card_metric_chart.dart';
part 'weather_card_summary.dart';

/// Insights' weather card: pick a day, pick a reading, see it hour by hour —
/// the shape iOS Weather uses.
///
/// **The whole card is free** (hard rule 1): seeing the weather you live in
/// is the app's own promise, and nothing here gates.
///
/// **No pressure, deliberately** — not the reading and not the alert. Both
/// belong to `PressureCard`, which is where they are sold; the alert sat here
/// first, which put a threshold next to readings it has nothing to do with.
///
/// The card is not tappable as a whole: it owns a day strip and a dropdown,
/// and a card-level tap would fight both. Which is also why it carries no
/// chevron.
class WeatherCard extends ConsumerWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<WeatherReport?> async = ref.watch(weatherReportProvider);
    // Survives a refresh: AsyncValue keeps the last value while refetching,
    // so a reload redraws the forecast it already had rather than blanking.
    final WeatherReport? report = async.value;

    return SdCardV2(
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // No heading: the tab above the card already names it, and the two
          // read as one label stated twice.
          children: <Widget>[
            if (report != null) ...<Widget>[
              _Forecast(report: report),
              // Bottom-right of the card, always, whenever Apple's data is
              // what was drawn. The real widget, not a plain Text: WeatherKit
              // requires the mark to LINK to Apple's attribution page, and
              // App Review checks for it.
              SizedBox(height: SdSpacingConstant.h12),
              const WeatherAttribution(),
            ] else if (async.isLoading)
              // Loading is NOT unavailable. Saying so while the first fetch
              // is still in flight told every user the feature was broken
              // for the length of a round trip.
              SizedBox(
                height: SdChartStyleV2.plotHeight,
                child: const Center(child: CircularProgressIndicator()),
              )
            else
              // One state for offline, no permission and a backend with no
              // WeatherKit credentials — hard rule 4 makes them the same
              // answer, so they must not look like three different bugs.
              Text(
                l10n.weatherUnavailable,
                style: AppTextStyle.bodyMedium.secondary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Day strip, the selected day's summary, the metric picker, then the hours.
class _Forecast extends ConsumerWidget {
  const _Forecast({required this.report});

  final WeatherReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final WeatherMetric metric = ref.watch(weatherMetricProvider);
    final List<WeatherDaily> week = report.week;
    // Clamped rather than trusted: the week slides forward at midnight, and
    // a report that came back short must not index off the end of it.
    final int selected = week.isEmpty
        ? 0
        : ref.watch(weatherDayProvider).clamp(0, week.length - 1);
    final WeatherDaily? day = week.isEmpty ? null : week[selected];
    final List<WeatherHourly> hours = day == null
        ? report.hours
        : report.hoursOn(day.date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (week.isNotEmpty) ...<Widget>[
          _DayStrip(week: week, selected: selected),
          SizedBox(height: SdSpacingConstant.h16),
        ],
        // Summary and dropdown share a row. The summary takes what is left
        // after the pill, which sizes to its own label — so the pill can
        // never be squeezed into an overflow, and the summary wraps instead.
        Row(
          children: <Widget>[
            Expanded(
              child: _DaySummary(
                day: day,
                // The live reading belongs to today alone — on any other day
                // the summary is the forecast's own high and low.
                current: selected == 0 ? report.current : null,
              ),
            ),
            SizedBox(width: SdSpacingConstant.w8),
            _MetricPicker(metric: metric),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h16),
        _MetricStrip(hours: hours, metric: metric),
      ],
    );
  }
}
