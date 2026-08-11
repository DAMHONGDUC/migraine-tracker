import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/alert_threshold_dialog.dart';
import '../../../../core/widgets/premium_gate.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../alerts/domain/entities/alerts_settings.dart';
import '../../../alerts/domain/enums/alert_registration_error.dart';
import '../../../alerts/providers.dart';
import '../../../premium/providers.dart';
import '../../../weather/domain/entities/weather_report.dart';
import '../../../weather/providers.dart';
import '../../domain/enums/weather_metric.dart';
import '../../providers.dart';

part 'weather_card_alert.dart';
part 'weather_card_condition.dart';
part 'weather_card_day_strip.dart';
part 'weather_card_metric.dart';
part 'weather_card_summary.dart';

/// Insights' weather card: pick a day, pick a reading, see it hour by hour —
/// the shape iOS Weather uses.
///
/// **The whole top half is free** (hard rule 1): seeing the weather you live
/// in is the app's own promise. **Only the alert below is premium**, and it
/// is the one thing on the card that gates.
///
/// **There is no pressure here, deliberately.** Pressure is `/pressure`'s
/// subject and its chart is premium; carrying it on this free card would be
/// the same reading given away on one screen and sold on another.
///
/// The card is not tappable as a whole: it owns a day strip, a dropdown and
/// a switch, and a card-level tap would fight all three. Which is also why it
/// carries no chevron.
class WeatherCard extends ConsumerWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final WeatherReport? report = ref.watch(weatherReportProvider).value;

    return SdCardV2(
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // No heading: the tab above the card already names it, and the
            // two read as one label stated twice.
            if (report == null)
              // One state for offline, no permission and a backend with no
              // WeatherKit credentials — hard rule 4 makes them the same
              // answer, so they must not look like three different bugs.
              Text(
                l10n.weatherUnavailable,
                style: AppTextStyle.bodyMedium.secondary,
              )
            else
              _Forecast(report: report),
            SizedBox(height: SdContentPaddingV2.sectionGap),
            const SdDividerV2(),
            SizedBox(height: SdContentPaddingV2.sectionGap),
            const _AlertControls(),
          ],
        ),
      ),
    );
  }
}

/// Day strip, the selected day's summary, the metric dropdown, then the
/// hours.
class _Forecast extends ConsumerWidget {
  const _Forecast({required this.report});

  final WeatherReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
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
            SdFilterChipV2<WeatherMetric>(
              label: WeatherMetricUtils.label(l10n, metric),
              selected: metric,
              options: WeatherMetric.values,
              optionLabelBuilder: (WeatherMetric value) =>
                  WeatherMetricUtils.label(l10n, value),
              onSelected: ref.read(weatherMetricProvider.notifier).set,
              sheetTitle: l10n.weatherMetricSheetTitle,
            ),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h16),
        _MetricStrip(hours: hours, metric: metric),
        // Apple requires the trademark wherever weather is shown.
        SizedBox(height: SdSpacingConstant.h12),
        Text(
          l10n.weatherAttribution,
          style: AppTextStyle.bodySmall.secondary,
        ),
      ],
    );
  }
}
