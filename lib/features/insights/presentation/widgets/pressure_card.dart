import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/alert_summary_tag.dart';
import '../../../../core/widgets/alert_threshold_sheet.dart';
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
import 'pressure_history_body.dart';
import 'trigger_verdict_body.dart';

part 'pressure_card_alert.dart';

/// Everything pressure, on two cards: what the weather is about to do and the
/// alert that acts on it, then what it has done to this user.
///
/// It was one card, which put a forecast, a verdict, a correlation, a history
/// chart and a switch in a single column — six subjects reading as one. The
/// split is the same as the activity and sleep tabs': the reading first, the
/// analysis drawn from it second.
class PressureCard extends ConsumerWidget {
  const PressureCard({required this.result, super.key});

  final CorrelationResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ONE pitch for the whole tab when locked, not one per card — which is why the locked branch stays a single titled card carrying the badge.
    if (!ref.watch(hasPremiumProvider)) {
      return InsightCard(
        title: context.l10n.insightsPressureTitle,
        trailing: const PremiumBadge(),
        child: PremiumUnlockPrompt(message: context.l10n.premiumLockedPressure),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // No title on either — the tab above them is it.
        InsightCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const PressureForecastBody(),
              SizedBox(height: SdContentPaddingV2.sectionGap),
              const SdDividerV2(),
              SizedBox(height: SdContentPaddingV2.sectionGap),
              // On the forecast's card, not the analysis': the alert fires on what the chart above it draws.
              const _AlertControls(),
            ],
          ),
        ),
        SizedBox(height: SdContentPaddingV2.sectionGap),
        InsightCard(
          title: context.l10n.insightsAnalysisTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // The conclusion first, then the working: everything below this line is the evidence it was drawn from.
              const TriggerVerdictBody(),
              SizedBox(height: SdContentPaddingV2.sectionGap),
              CorrelationBody(result: result),
              SizedBox(height: SdContentPaddingV2.sectionGap),
              // Directly under the sentence it draws: the share and the picture of the same month belong to one another.
              const PressureHistoryBody(),
            ],
          ),
        ),
      ],
    );
  }
}
