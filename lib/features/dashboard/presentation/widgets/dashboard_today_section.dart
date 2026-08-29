import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/duration_label.dart';
import '../../../../core/extensions/step_count_label.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../health/domain/entities/sleep_summary.dart';
import '../../../health/domain/entities/step_summary.dart';
import '../../../health/providers.dart';
import '../../../insights/domain/enums/insights_tab.dart';
import '../../../premium/providers.dart';
import '../../../weather/domain/entities/weather_report.dart';
import '../../../weather/providers.dart';

/// What today's readings say, in one line each, straight to the card that explains them.
class DashboardTodaySection extends ConsumerWidget {
  const DashboardTodaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final List<_Reading> readings = _readings(l10n, ref);

    if (readings.isEmpty) return const SizedBox.shrink();

    return SdCardV2(
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.dashboardTodayTitle, style: AppTextStyle.titleMedium),
            SizedBox(height: SdSpacingConstant.h8),
            // Between rows only — a rule above the first would sit on the card's own edge.
            for (final (int index, _Reading reading) in readings.indexed) ...[
              if (index > 0) const SdDividerV2(),
              _ReadingRow(reading: reading),
            ],
          ],
        ),
      ),
    );
  }

  /// The three, in the order Insights lists them, skipping any with no value.
  List<_Reading> _readings(AppLocalizations l10n, WidgetRef ref) {
    final WeatherReport? weather = ref.watch(weatherReportProvider).value;
    final StepSummary? steps = ref.watch(stepSummaryProvider).value;
    final SleepSummary? sleep = ref.watch(sleepSummaryProvider).value;
    final WeatherConditions? now = weather?.current;
    final bool hasPremium = ref.watch(hasPremiumProvider);

    return <_Reading>[
      // The one premium row: the pressure reading is what is sold, and a free user tapping through would land on a card of pitches.
      if (now?.pressureHpa case final double value when hasPremium)
        _Reading(
          icon: AppIconConstant.pressure,
          label: l10n.insightsPressureTitle,
          value: l10n.insightsPressureValue('${value.round()}'),
          tab: InsightsTab.pressure,
        ),
      if (steps?.latest?.count case final int value)
        _Reading(
          icon: AppIconConstant.steps,
          label: l10n.activityCardTitle,
          value: value.label(l10n),
          tab: InsightsTab.activity,
        ),
      if (sleep?.latest?.duration case final Duration value)
        _Reading(
          icon: AppIconConstant.sleep,
          label: l10n.sleepCardTitle,
          value: value.label(l10n),
          tab: InsightsTab.sleep,
        ),
    ];
  }
}

/// One line of the section, ready to draw.
class _Reading {
  const _Reading({
    required this.icon,
    required this.label,
    required this.value,
    required this.tab,
  });

  final IconData icon;

  /// Both already localized. [label] is the Insights tab's own name, from the same ARB key, so the row and the card it opens cannot disagree.
  final String label;
  final String value;

  final InsightsTab tab;
}

class _ReadingRow extends ConsumerWidget {
  const _ReadingRow({required this.reading});

  final _Reading reading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => NavigationUtils.toInsights(context, ref, reading.tab),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h12),
        child: Row(
          children: <Widget>[
            SdIconV2(
              icon: reading.icon,
              size: AppIconSize.row,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: SdSpacingConstant.w12),
            Expanded(
              child: Text(
                reading.label,
                style: AppTextStyle.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: SdSpacingConstant.w8),
            Text(reading.value, style: AppTextStyle.bodyMedium.w600),
            SizedBox(width: SdSpacingConstant.w4),
            SdIconV2(
              icon: AppIconConstant.disclosure,
              size: AppIconSize.affordance,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
