import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import 'insight_card.dart';
import 'sleep_correlation_body.dart';

/// The sleep insight on its own card. Sleep keeps a card of its own — it is
/// the night, where exertion and steps are both the day — and [onTap] is how
/// Insights opens the detail screen that carries its connect switch.
class SleepCorrelationCard extends StatelessWidget {
  const SleepCorrelationCard({this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InsightCard(
      title: context.l10n.insightsSleepTitle,
      onTap: onTap,
      child: const SleepCorrelationBody(),
    );
  }
}
