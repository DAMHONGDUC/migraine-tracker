import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/premium_gate.dart';
import '../../../premium/providers.dart';
import '../../domain/entities/correlation_result.dart';
import 'correlation_body.dart';
import 'insight_card.dart';

/// The correlation on its own card, as the pressure detail screen shows it. Insights folds this into `PressureCard` alongside the forecast instead.
class CorrelationCard extends ConsumerWidget {
  const CorrelationCard({required this.result, super.key});

  final CorrelationResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPremium = ref.watch(hasPremiumProvider);

    return InsightCard(
      title: context.l10n.insightsCorrelationTitle,
      trailing: hasPremium ? null : const PremiumBadge(),
      child: CorrelationBody(result: result),
    );
  }
}
