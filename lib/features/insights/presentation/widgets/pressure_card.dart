import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/premium_gate.dart';
import '../../../premium/providers.dart';
import '../../domain/entities/correlation_result.dart';
import 'correlation_body.dart';
import 'insight_card.dart';
import 'pressure_forecast_body.dart';

/// Insights' one pressure entry: the forecast and the correlation on a single
/// card, opening the detail screen where the alert controls live.
///
/// Two cards before, which put the same subject in two places and neither of
/// them next to the alert it drives.
class PressureCard extends ConsumerWidget {
  const PressureCard({required this.result, super.key});

  final CorrelationResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPremium = ref.watch(hasPremiumProvider);

    return InsightCard(
      title: context.l10n.insightsPressureTitle,
      trailing: hasPremium ? null : const PremiumBadge(),
      // Nothing to open without premium: the detail screen is the forecast
      // and the alert controls, both of which are premium's.
      onTap: hasPremium
          ? () => context.pushNamed(AppRoutes.pressure.name)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Free users never build the chart, so no forecast is fetched for
          // them — they get the pitch instead, which is what the paywall sells.
          if (hasPremium)
            const PressureForecastBody()
          else
            Text(
              context.l10n.premiumLockedForecast,
              style: AppTextStyle.bodyMedium,
            ),
          SizedBox(height: SdContentPaddingV2.sectionGap),
          CorrelationBody(result: result),
        ],
      ),
    );
  }
}
