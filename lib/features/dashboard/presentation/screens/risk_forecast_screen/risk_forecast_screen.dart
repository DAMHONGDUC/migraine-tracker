import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/log_tag_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/navigation_utils.dart';
import '../../../../../core/theme/app_icon_constant.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/analysis_info_sheet.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../insights/domain/entities/risk_score.dart';
import '../../../../insights/providers.dart';
import '../../widgets/risk_band_style.dart';

part 'risk_forecast_screen_reasons.dart';
part 'risk_forecast_screen_week_chart.dart';

/// The working behind the dashboard's risk card: today's score, every day of the week with its number, and what moved today's.
class RiskForecastScreen extends ConsumerWidget {
  const RiskForecastScreen({super.key});

  void _openInfo(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    SdLogger.action(LogTagConstant.riskForecast, 'Risk info opened');
    AnalysisInfoSheet(
      title: l10n.riskInfoTitle,
      paragraphs: <String>[
        l10n.riskInfoWhat,
        l10n.riskInfoHow,
        l10n.riskInfoMissing,
        l10n.riskInfoThresholds,
      ],
    ).show(context);
  }

  void _openPressure(BuildContext context, WidgetRef ref) {
    SdLogger.action(LogTagConstant.riskForecast, 'Pressure tab opened');
    NavigationUtils.toPressure(context, ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final RiskForecast? forecast = ref.watch(riskForecastProvider).value;
    final DailyRisk? today = forecast?.today;
    final double gap = SdContentPaddingV2.sectionGap;

    return SdScaffoldV2(
      title: Text(l10n.riskCardTitle, style: AppTextStyle.titleLarge),
      actions: <Widget>[
        SdAppBarButtonV2(
          icon: AppIconConstant.info,
          tooltip: l10n.insightsExplainTooltip,
          onPressed: () => _openInfo(context),
        ),
        SizedBox(width: SdSpacingConstant.w12),
      ],
      // Pinned: the door to the Pressure tab holds the bottom edge however short or long the working above it is.
      body: SdActionViewV2(
        placement: SdActionsPlacementV2.pinned,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.riskCardSubtitle,
              style: AppTextStyle.bodySmall.secondary,
            ),
            SizedBox(height: SdSpacingConstant.h12),
            if (forecast == null || today == null || !forecast.isReady)
              Text(l10n.riskPending, style: AppTextStyle.bodyMedium.secondary)
            else ...<Widget>[
              _TodayScore(today: today),
              SizedBox(height: gap),
              SdCardV2(
                child: Padding(
                  padding: EdgeInsets.all(SdSpacingConstant.w12),
                  child: _WeekChart(days: forecast.days),
                ),
              ),
              if (_Reasons.hasAny(today)) ...<Widget>[
                SizedBox(height: gap),
                SdCardV2(
                  child: Padding(
                    padding: EdgeInsets.all(SdSpacingConstant.w16),
                    child: _Reasons(today: today),
                  ),
                ),
              ],
            ],
          ],
        ),
        actions: <Widget>[
          // The door the card used to be: the pressure forecast the score is built on, drawn in full.
          SdButtonV2(
            variant: SdButtonVariantV2.outlined,
            label: l10n.riskOpenPressure,
            onPressed: () => _openPressure(context, ref),
          ),
        ],
      ),
    );
  }
}

/// Today's number and the word for it, large.
class _TodayScore extends StatelessWidget {
  const _TodayScore({required this.today});

  final DailyRisk today;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Color color = RiskBandStyle.color(today.band);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        // The percent sign is the point: a bare "62" beside a word reads as a rating out of ten as easily as a probability.
        Text(
          l10n.riskPercent(today.score),
          style: AppTextStyle.displaySmall.copyWith(color: color),
        ),
        SizedBox(width: SdSpacingConstant.w8),
        Text(
          RiskBandStyle.label(today.band, l10n),
          style: AppTextStyle.titleSmall.copyWith(color: color),
        ),
      ],
    );
  }
}
