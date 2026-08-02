part of 'correlation_card.dart';

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
            AppIcon(
              icon: Icons.lock_outline,
              size: AppSpacingConstant.r20,
              color: context.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: AppSpacingConstant.w8),
            Expanded(
              child: Text(
                l10n.insightsInsufficientData(remaining),
                style: AppTextStyle.bodyMedium,
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
          style: AppTextStyle.bodySmall.secondary,
        ),
      ],
    );
  }
}
