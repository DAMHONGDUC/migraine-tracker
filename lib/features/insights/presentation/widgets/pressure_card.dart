import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
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
      // The badge marks the alert, which is the premium half of this screen —
      // the forecast below it is free.
      trailing: hasPremium ? null : const PremiumBadge(),
      // Open for everyone: the detail screen carries the free forecast as
      // well as the alert controls, and the switch there does its own gating.
      onTap: () => context.pushNamed(AppRoutes.pressure.name),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Free, and fetched for everyone: seeing the pressure they live in
          // is the app's own promise, and the alert is what is sold.
          const PressureForecastBody(),
          SizedBox(height: SdContentPaddingV2.sectionGap),
          CorrelationBody(result: result),
        ],
      ),
    );
  }
}
