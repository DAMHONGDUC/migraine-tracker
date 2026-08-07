import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/exertion_correlation_result.dart';
import 'exertion_correlation_body.dart';
import 'insight_card.dart';

/// The exertion self-report on its own card, as the activity detail screen
/// shows it. Insights folds this into `ActivityCard` alongside the steps.
class ExertionCorrelationCard extends StatelessWidget {
  const ExertionCorrelationCard({required this.result, super.key});

  final ExertionCorrelationResult result;

  @override
  Widget build(BuildContext context) {
    return InsightCard(
      title: context.l10n.insightsExertionTitle,
      child: ExertionCorrelationBody(result: result),
    );
  }
}
