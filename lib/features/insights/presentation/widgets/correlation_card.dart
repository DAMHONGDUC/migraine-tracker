import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../premium/presentation/widgets/premium_gate.dart';
import '../../../premium/providers.dart';
import '../../domain/entities/correlation_result.dart';

part 'correlation_card_insight.dart';
part 'correlation_card_insufficient_data.dart';
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

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacingConstant.w20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.insightsCorrelationTitle,
                    style: AppTextStyle.titleMedium,
                  ),
                ),
                if (!hasPremium) const PremiumBadge(),
              ],
            ),
            SizedBox(height: AppSpacingConstant.h16),
            switch (result) {
              // Free: how far off the insight is.
              final CorrelationInsufficientData r => _InsufficientData(
                result: r,
              ),
              // Premium: the analysis. Teased, never computed into the tree.
              _ when !hasPremium => const _Teaser(),
              CorrelationNoVariation() => _NoVariation(),
              final CorrelationInsight r => _Insight(result: r),
            },
          ],
        ),
      ),
    );
  }
}
