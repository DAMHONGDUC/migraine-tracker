import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/dashboard_chevron.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../insights/domain/entities/risk_score.dart';
import '../../../insights/providers.dart';
import '../../../premium/providers.dart';
import 'risk_band_style.dart';

part 'risk_score_card_mini_week.dart';

/// How likely the next seven days are to hurt, at a glance: one line and a mini week. The whole card opens `RiskForecastScreen`, where the working is.
///
/// **Premium users only, and absent rather than locked for everyone else.** The
/// dashboard has one premium door — the banner — and a second locked card on
/// the same screen is two pitches for one purchase (see
/// `lib/features/dashboard/CLAUDE.md`).
class RiskScoreCard extends ConsumerWidget {
  const RiskScoreCard({super.key});

  /// Whether this card has anything to draw: premium, and a forecast with a today in it. The screen asks before placing it, so a card that drew nothing leaves no gap.
  static bool isShown(WidgetRef ref) =>
      ref.watch(hasPremiumProvider) &&
      ref.watch(riskForecastProvider).value?.today != null;

  void _open(BuildContext context, DailyRisk today) {
    SdLogger.action(
      LogTagConstant.riskForecast,
      'Risk forecast opened',
      <String, Object>{'score': today.score, 'band': today.band.name},
    );
    context.pushNamed<void>(AppRoutes.riskForecast.name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    if (!isShown(ref)) return const SizedBox.shrink();

    final RiskForecast forecast = ref.watch(riskForecastProvider).value!;
    final DailyRisk today = forecast.today!;
    final bool ready = forecast.isReady;

    return SdCardV2(
      // No tap before the score starts: the screen would only repeat the line below.
      onTap: ready ? () => _open(context, today) : null,
      child: Padding(
        padding: EdgeInsets.all(SdSpacingConstant.w16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(l10n.riskCardTitle, style: AppTextStyle.titleSmall),
                      // The window and the word "prediction" are what stop a percentage being read as a measurement.
                      Text(
                        l10n.riskCardSubtitle,
                        style: AppTextStyle.bodySmall.secondary,
                      ),
                    ],
                  ),
                ),
                if (ready) ...<Widget>[
                  SizedBox(width: SdSpacingConstant.w8),
                  _TodayBadge(today: today),
                  const DashboardChevron(),
                ],
              ],
            ),
            if (!ready) ...<Widget>[
              SizedBox(height: SdSpacingConstant.h8),
              Text(l10n.riskPending, style: AppTextStyle.bodySmall.secondary),
            ] else ...<Widget>[
              SizedBox(height: SdSpacingConstant.h12),
              _MiniWeek(days: forecast.days),
            ],
          ],
        ),
      ),
    );
  }
}
