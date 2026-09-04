import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/analysis_info_sheet.dart';
import '../../../../core/widgets/dashboard_chevron.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../insights/domain/entities/risk_score.dart';
import '../../../insights/providers.dart';
import '../../../premium/providers.dart';

part 'risk_score_card_strip.dart';

/// How likely the next seven days are to hurt, and the readings that decided it.
///
/// **Premium users only, and absent rather than locked for everyone else.** The
/// dashboard has one premium door — the banner — and a second locked card on
/// the same screen is two pitches for one purchase (see
/// `lib/features/dashboard/CLAUDE.md`).
class RiskScoreCard extends ConsumerWidget {
  const RiskScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    if (!ref.watch(hasPremiumProvider)) return const SizedBox.shrink();

    final RiskForecast? forecast = ref.watch(riskForecastProvider).value;
    final DailyRisk? today = forecast?.today;

    // Nothing to draw yet, and nothing to promise either: the card appears with the score.
    if (forecast == null || today == null) return const SizedBox.shrink();

    return SdCardV2(
      surface: SdCardSurfaceV2.elevated,
      // The pressure tab is where the forecast this is built on is drawn in full.
      onTap: () => NavigationUtils.toPressure(context, ref),
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.riskCardTitle,
                    style: AppTextStyle.titleSmall,
                  ),
                ),
                // The same glyph, tooltip and sheet every analysis card on Insights carries — this one is an analysis too, it just lives on the dashboard.
                SdIconButtonV2(
                  icon: SdIconV2(
                    icon: AppIconConstant.info,
                    size: AppIconSize.small,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  tooltip: l10n.insightsExplainTooltip,
                  onPressed: () => AnalysisInfoSheet(
                    title: l10n.riskInfoTitle,
                    paragraphs: <String>[
                      l10n.riskInfoWhat,
                      l10n.riskInfoHow,
                      l10n.riskInfoMissing,
                      l10n.riskInfoThresholds,
                    ],
                  ).show(context),
                ),
                const DashboardChevron(),
              ],
            ),
            // Under the title rather than beside it: the window and the word "prediction" are what stop a percentage being read as a measurement.
            Text(
              l10n.riskCardSubtitle,
              style: AppTextStyle.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: SdSpacingConstant.h12),
            if (!forecast.isReady)
              Text(
                l10n.riskPending,
                style: AppTextStyle.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else ...<Widget>[
              _TodayScore(today: today),
              SizedBox(height: SdSpacingConstant.h12),
              _WeekChart(days: forecast.days),
              SizedBox(height: SdSpacingConstant.h12),
              _Reasons(today: today),
            ],
          ],
        ),
      ),
    );
  }
}
