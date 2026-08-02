part of 'sleep_correlation_card.dart';

/// Same shape as the pressure card's progress state: how far off the insight
/// is, so the road to it is visible rather than a locked door.
class _SleepInsufficientDataBody extends StatelessWidget {
  const _SleepInsufficientDataBody({required this.result});

  final SleepInsufficientData result;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            AppIcon(
              icon: Icons.hourglass_empty,
              size: AppSpacingConstant.r20,
              color: context.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: AppSpacingConstant.w8),
            Expanded(
              child: Text(
                l10n.insightsSleepInsufficientData(
                  result.requiredNights,
                  result.requiredPerGroup,
                ),
                style: AppTextStyle.bodyMedium,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacingConstant.h12),
        LinearProgressIndicator(
          value: (result.nightsWithSleep / result.requiredNights).clamp(0, 1),
          minHeight: AppSpacingConstant.h6,
          borderRadius: BorderRadius.circular(AppSpacingConstant.r3),
        ),
        SizedBox(height: AppSpacingConstant.h8),
        Text(
          l10n.insightsSleepProgressCaption(
            result.nightsWithSleep,
            result.requiredNights,
          ),
          style: AppTextStyle.bodySmall.secondary,
        ),
      ],
    );
  }
}
