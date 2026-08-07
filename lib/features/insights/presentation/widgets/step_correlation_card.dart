import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import 'insight_card.dart';
import 'step_correlation_body.dart';

/// The step insight on its own card, as the activity detail screen shows it.
/// Insights folds this into `ActivityCard` alongside the exertion self-report.
class StepCorrelationCard extends StatelessWidget {
  const StepCorrelationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InsightCard(
      title: context.l10n.insightsStepsTitle,
      child: const StepCorrelationBody(),
    );
  }
}
