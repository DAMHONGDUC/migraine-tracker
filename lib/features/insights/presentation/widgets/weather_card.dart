import 'dart:math' show min;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/utils/chart_axis_utils.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/alert_threshold_dialog.dart';
import '../../../../core/widgets/premium_gate.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../alerts/domain/entities/alerts_settings.dart';
import '../../../alerts/domain/enums/alert_registration_error.dart';
import '../../../alerts/providers.dart';
import '../../../premium/providers.dart';
import '../../../weather/domain/entities/weather_report.dart';
import '../../../weather/providers.dart';
import '../../domain/enums/weather_view.dart';
import '../../providers.dart';

part 'weather_card_alert.dart';
part 'weather_card_chart.dart';
part 'weather_card_condition.dart';
part 'weather_card_current.dart';
part 'weather_card_daily.dart';
part 'weather_card_details.dart';
part 'weather_card_hourly.dart';

/// Insights' weather card: what the air is doing, then the alert that acts
/// on it.
///
/// **The top half is free for everyone** — seeing the pressure you live in is
/// the app's own promise (hard rule 1), and this card widens that from the
/// pressure line alone to everything WeatherKit returns for the location.
/// **Only the alert below is premium**, and it is the one thing on the card
/// that gates.
///
/// The card is not tappable as a whole, unlike the other insight cards: it
/// owns a segmented control and a switch, and a card-level tap would fight
/// both. Which is also why it carries no chevron.
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
            Text(l10n.weatherCardTitle, style: AppTextStyle.titleMedium),
            SizedBox(height: SdSpacingConstant.h16),
            if (report == null)
              // One state for offline, no permission and a backend with no
              // WeatherKit credentials — hard rule 4 makes them the same
              // answer, so they must not look like three different bugs.
              Text(
                l10n.weatherUnavailable,
                style: AppTextStyle.bodyMedium.secondary,
              )
            else ...<Widget>[
              _Current(current: report.current),
              SizedBox(height: SdSpacingConstant.h20),
              _ViewToggle(),
              SizedBox(height: SdSpacingConstant.h16),
              _ViewBody(report: report),
              // Apple requires the trademark wherever weather is shown.
              SizedBox(height: SdSpacingConstant.h12),
              Text(
                l10n.weatherAttribution,
                style: AppTextStyle.bodySmall.secondary,
              ),
            ],
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

/// The segmented control that picks which face shows.
class _ViewToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final WeatherView view = ref.watch(weatherViewProvider);

    return SdSegmentedTabsV2(
      segments: <SdSegmentV2>[
        SdSegmentV2(label: l10n.weatherViewChart),
        SdSegmentV2(label: l10n.weatherViewHourly),
        SdSegmentV2(label: l10n.weatherViewDaily),
        SdSegmentV2(label: l10n.weatherViewDetails),
      ],
      selectedIndex: WeatherView.values.indexOf(view),
      onSelected: (int index) =>
          ref.read(weatherViewProvider.notifier).set(WeatherView.values[index]),
    );
  }
}

/// Whichever face the toggle selected.
class _ViewBody extends ConsumerWidget {
  const _ViewBody({required this.report});

  final WeatherReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(weatherViewProvider)) {
      WeatherView.chart => _PressureChart(hours: report.hours),
      WeatherView.hourly => _HourlyStrip(hours: report.hours),
      WeatherView.daily => _DailyList(days: report.days),
      WeatherView.details => _DetailsGrid(
        current: report.current,
        hours: report.hours,
      ),
    };
  }
}
