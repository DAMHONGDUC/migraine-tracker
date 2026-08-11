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
      // The badge marks the whole card now: the forecast chart and the alert
      // are both premium, and the correlation under them already was.
      trailing: hasPremium ? null : const PremiumBadge(),
      // Still open to everyone — the screen says what it would show and how
      // to unlock it, which is the pitch. Free weather lives on `WeatherCard`.
      onTap: () => context.pushNamed(AppRoutes.pressure.name),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Gates itself, and a free user issues no WeatherKit call for it.
          const PressureForecastBody(),
          SizedBox(height: SdContentPaddingV2.sectionGap),
          CorrelationBody(result: result),
        ],
      ),
    );
  }
}
