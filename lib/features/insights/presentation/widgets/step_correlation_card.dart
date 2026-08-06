import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/step_count_label.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/step_correlation_result.dart';
import '../../providers.dart';
import 'insight_card.dart';
import 'insight_progress_body.dart';

part 'step_correlation_card_insight.dart';
part 'step_correlation_card_not_connected.dart';
part 'step_correlation_card_no_variation.dart';

/// Stat tile for the step insight: did attacks follow the low-activity days?
///
/// The whole card is premium (the Insights screen wraps it in a
/// `PremiumGate`), so unlike the pressure card there is no free branch and no
/// teaser — a free user never builds it and no HealthKit read is issued for
/// them at all.
///
/// While the read is in flight the card renders nothing rather than a
/// spinner: a card that pops in half a second later is calmer than one that
/// flickers a placeholder first.
class StepCorrelationCard extends ConsumerWidget {
  const StepCorrelationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<StepCorrelationResult> result = ref.watch(
      stepCorrelationProvider,
    );

    return switch (result) {
      AsyncData(value: final StepCorrelationResult value) => _Card(
        result: value,
      ),
      // A HealthKit failure is not worth an error state on a secondary card.
      _ => const SizedBox.shrink(),
    };
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.result});

  final StepCorrelationResult result;

  @override
  Widget build(BuildContext context) {
    return InsightCard(
      title: context.l10n.insightsStepsTitle,
      child: switch (result) {
        StepNotConnected() => const _StepNotConnected(),
        final StepInsufficientData r => InsightProgressBody(
          icon: Icons.directions_walk,
          message: context.l10n.insightsStepsInsufficientData(
            r.requiredDays,
            r.requiredPerGroup,
          ),
          progress: r.daysWithSteps / r.requiredDays,
          caption: context.l10n.insightsStepsProgressCaption(
            r.daysWithSteps,
            r.requiredDays,
          ),
        ),
        StepNoVariation() => const _StepNoVariationBody(),
        final StepInsight r => _StepInsightBody(result: r),
      },
    );
  }
}
