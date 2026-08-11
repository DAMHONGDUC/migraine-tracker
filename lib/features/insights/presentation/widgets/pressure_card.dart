import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/alert_threshold_dialog.dart';
import '../../../../core/widgets/premium_gate.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../alerts/domain/entities/alerts_settings.dart';
import '../../../alerts/domain/enums/alert_registration_error.dart';
import '../../../alerts/providers.dart';
import '../../../premium/providers.dart';
import '../../domain/entities/correlation_result.dart';
import 'correlation_body.dart';
import 'insight_card.dart';
import 'pressure_forecast_body.dart';

part 'pressure_card_alert.dart';

/// Everything pressure, on one card: the forecast, what it has done to this
/// user, and the alert that acts on both.
///
/// **There is no detail screen behind it.** `/pressure` existed to hold the
/// alert controls; they are here now, so the card is the destination rather
/// than a preview of one — which is why it takes no `onTap` and draws no
/// chevron.
///
/// The whole card is premium: the forecast chart gates itself, the
/// correlation already did, and the alert is what is being sold.
class PressureCard extends ConsumerWidget {
  const PressureCard({required this.result, super.key});

  final CorrelationResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasPremium = ref.watch(hasPremiumProvider);

    return InsightCard(
      title: context.l10n.insightsPressureTitle,
      trailing: hasPremium ? null : const PremiumBadge(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Gates itself, and a free user issues no WeatherKit call for it.
          const PressureForecastBody(),
          SizedBox(height: SdContentPaddingV2.sectionGap),
          CorrelationBody(result: result),
          // Premium only, and NOT a second pitch when locked: the forecast
          // above already carries the card's one Unlock button, and three
          // stacked pitches read as three broken sections.
          if (hasPremium) ...<Widget>[
            SizedBox(height: SdContentPaddingV2.sectionGap),
            const SdDividerV2(),
            SizedBox(height: SdContentPaddingV2.sectionGap),
            const _AlertControls(),
          ],
        ],
      ),
    );
  }
}
