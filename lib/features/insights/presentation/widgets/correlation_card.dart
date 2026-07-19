import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../premium/presentation/widgets/premium_gate.dart';
import '../../../premium/providers.dart';
import '../../domain/entities/correlation_result.dart';

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
                    style: context.textTheme.titleMedium,
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

/// Shown once the user HAS enough data but isn't premium — the value moment
/// the paywall is sold on. Deliberately carries no analysis output.
class _Teaser extends StatelessWidget {
  const _Teaser();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.premiumLockedCorrelation,
          style: context.textTheme.bodyMedium,
        ),
        SizedBox(height: AppSpacingConstant.h12),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton.tonal(
            onPressed: () => context.push(AppRoutes.paywall),
            child: Text(l10n.premiumUnlock),
          ),
        ),
      ],
    );
  }
}

class _InsufficientData extends StatelessWidget {
  const _InsufficientData({required this.result});

  final CorrelationInsufficientData result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final remaining = result.requiredAttacks - result.attacksWithWeather;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: AppSpacingConstant.r20,
              color: context.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: AppSpacingConstant.w8),
            Expanded(
              child: Text(
                l10n.insightsInsufficientData(remaining),
                style: context.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacingConstant.h12),
        LinearProgressIndicator(
          value: result.attacksWithWeather / result.requiredAttacks,
          minHeight: AppSpacingConstant.h6,
          borderRadius: BorderRadius.circular(AppSpacingConstant.r3),
        ),
        SizedBox(height: AppSpacingConstant.h8),
        Text(
          l10n.insightsProgressCaption(
            result.attacksWithWeather,
            result.requiredAttacks,
          ),
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _NoVariation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.insightsNoVariation,
      style: context.textTheme.bodyMedium,
    );
  }
}

class _Insight extends StatelessWidget {
  const _Insight({required this.result});

  final CorrelationInsight result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final threshold = result.dropThresholdHpa
        .toStringAsFixed(result.dropThresholdHpa % 1 == 0 ? 0 : 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: result.dropSharePercent),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Text(
            '${value.round()}%',
            style: context.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: AppSpacingConstant.h4),
        Text(
          l10n.insightsDropShareSentence(threshold),
          style: context.textTheme.bodyMedium,
        ),
        SizedBox(height: AppSpacingConstant.h12),
        Text(
          l10n.insightsAnalyzedCaption(result.attacksAnalyzed),
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
