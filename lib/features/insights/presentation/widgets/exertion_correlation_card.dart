import 'package:flutter/material.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/exertion_correlation_result.dart';
import 'insight_card.dart';
import 'insight_progress_body.dart';

part 'exertion_correlation_card_insight.dart';
part 'exertion_correlation_card_no_variation.dart';

/// Stat tile for the exertion self-report insight.
///
/// Free, unlike [CorrelationCard]: exertion is self-reported, not read from
/// HealthKit, so there is no premium data boundary to gate — the analysis
/// itself is always built.
class ExertionCorrelationCard extends StatelessWidget {
  const ExertionCorrelationCard({required this.result, super.key});

  final ExertionCorrelationResult result;

  @override
  Widget build(BuildContext context) {
    return InsightCard(
      title: context.l10n.insightsExertionTitle,
      child: switch (result) {
        // No padlock: this card is free, so nothing here is ever locked.
        final ExertionInsufficientData r => InsightProgressBody(
          icon: Icons.timeline,
          message: context.l10n.insightsExertionInsufficientData(
            r.requiredAttacks - r.attacksWithExertion,
          ),
          progress: r.attacksWithExertion / r.requiredAttacks,
          caption: context.l10n.insightsExertionProgressCaption(
            r.attacksWithExertion,
            r.requiredAttacks,
          ),
        ),
        ExertionNoVariation() => _NoVariation(),
        final ExertionInsight r => _Insight(result: r),
      },
    );
  }
}
