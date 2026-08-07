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
part 'correlation_card_progress.dart';
part 'correlation_card_teaser.dart';

/// Stat tile for the headline correlation insight.
///
/// Premium sees the analysis from the first attack — as counts while the
/// sample is tiny, then as a percentage carrying a "still settling" note.
/// Free keeps the "keep logging" progress until the insight is worth paying
/// for: that's the road to the value moment, and no number reaches the tree.
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
        // Nothing carries weather yet — there is no figure, for anyone.
        CorrelationInsufficientData() => _Progress(result: result),
        // Free: how far off the insight is.
        _ when !hasPremium && result.isPreliminary => _Progress(result: result),
        // Free, enough data: teased, never computed into the tree.
        _ when !hasPremium => const _Teaser(),
        CorrelationNoVariation() => _NoVariation(),
        final CorrelationInsight r => _Insight(result: r),
      },
    );
  }
}
