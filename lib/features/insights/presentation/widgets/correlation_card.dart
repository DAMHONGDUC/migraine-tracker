import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/correlation_result.dart';

/// Stat tile for the headline correlation insight. Three states:
/// locked (not enough data), no-variation, and the hero percentage.
class CorrelationCard extends StatelessWidget {
  const CorrelationCard({required this.result, super.key});

  final CorrelationResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.insightsCorrelationTitle,
              style: context.textTheme.titleMedium,
            ),
            SizedBox(height: 16.h),
            switch (result) {
              final CorrelationInsufficientData r => _InsufficientData(
                result: r,
              ),
              CorrelationNoVariation() => _NoVariation(),
              final CorrelationInsight r => _Insight(result: r),
            },
          ],
        ),
      ),
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
              size: 20.r,
              color: context.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                l10n.insightsInsufficientData(remaining),
                style: context.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        LinearProgressIndicator(
          value: result.attacksWithWeather / result.requiredAttacks,
          minHeight: 6.h,
          borderRadius: BorderRadius.circular(3.r),
        ),
        SizedBox(height: 8.h),
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
        SizedBox(height: 4.h),
        Text(
          l10n.insightsDropShareSentence(threshold),
          style: context.textTheme.bodyMedium,
        ),
        SizedBox(height: 12.h),
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
