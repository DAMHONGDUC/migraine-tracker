import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/index.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/navigation_utils.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/premium_gate.dart';
import '../../../premium/providers.dart';
import '../../domain/entities/correlation_result.dart';
import 'insight_card.dart';
import 'insight_progress_body.dart';

part 'correlation_card_insight.dart';
part 'correlation_card_no_variation.dart';
part 'correlation_card_teaser.dart';

/// Stat tile for the headline correlation insight.
///
/// Free users still get the "keep logging" progress — that's the road to the
/// value moment, not premium data. The analysis itself (the percentage, or
/// "your weather is too uniform") is premium: for a free user the result
/// widget is never built, so no number exists in the tree to leak.
class CorrelationCard extends ConsumerWidget {
  const CorrelationCard({required this.result, super.key});

  final CorrelationResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPremium = ref.watch(hasPremiumProvider);

    return InsightCard(
      title: context.l10n.insightsCorrelationTitle,
      trailing: hasPremium ? null : const PremiumBadge(),
      child: switch (result) {
        // Free: how far off the insight is.
        final CorrelationInsufficientData r => InsightProgressBody(
          icon: Icons.lock_outline,
          message: context.l10n.insightsInsufficientData(
            r.requiredAttacks - r.attacksWithWeather,
          ),
          progress: r.attacksWithWeather / r.requiredAttacks,
          caption: context.l10n.insightsProgressCaption(
            r.attacksWithWeather,
            r.requiredAttacks,
          ),
        ),
        // Premium: the analysis. Teased, never computed into the tree.
        _ when !hasPremium => const _Teaser(),
        CorrelationNoVariation() => _NoVariation(),
        final CorrelationInsight r => _Insight(result: r),
      },
    );
  }
}
