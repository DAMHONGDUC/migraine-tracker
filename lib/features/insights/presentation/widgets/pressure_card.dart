import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/alert_threshold_dialog.dart';
import '../../../../core/widgets/premium_gate.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../alerts/domain/entities/alerts_settings.dart';
import '../../../alerts/domain/enums/alert_registration_error.dart';
import '../../../alerts/providers.dart';
import '../../../premium/providers.dart';
import '../../domain/entities/correlation_result.dart';
import '../../providers.dart';
import 'correlation_body.dart';
import 'insight_card.dart';
import 'pressure_forecast_body.dart';
import 'pressure_history_body.dart';
import 'trigger_verdict_body.dart';

part 'pressure_card_alert.dart';

/// Everything pressure, on one card: the forecast, what it has done to this user, and the alert that acts on both.
class PressureCard extends ConsumerWidget {
  const PressureCard({required this.result, super.key});

  final CorrelationResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasPremium = ref.watch(hasPremiumProvider);

    return InsightCard(
      title: context.l10n.insightsPressureTitle,
      trailing: hasPremium ? null : const PremiumBadge(),
      // ONE pitch for the whole card when locked, not one per section.
      child: hasPremium
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // The conclusion first, then the working: everything below this line is the evidence it was drawn from.
                const TriggerVerdictBody(),
                SizedBox(height: SdContentPaddingV2.sectionGap),
                const PressureForecastBody(),
                SizedBox(height: SdContentPaddingV2.sectionGap),
                CorrelationBody(result: result),
                SizedBox(height: SdContentPaddingV2.sectionGap),
                // Directly under the sentence it draws: the share and the picture of the same month belong to one another.
                const PressureHistoryBody(),
                SizedBox(height: SdContentPaddingV2.sectionGap),
                const SdDividerV2(),
                SizedBox(height: SdContentPaddingV2.sectionGap),
                const _AlertControls(),
              ],
            )
          : PremiumUnlockPrompt(message: context.l10n.premiumLockedPressure),
    );
  }
}
