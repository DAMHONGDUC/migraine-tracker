part of 'activity_card.dart';

/// The premium half: how attacks line up with exertion, and with steps.
class _Analysis extends ConsumerWidget {
  const _Analysis({required this.result, required this.hasHealth});

  final ExertionCorrelationResult result;

  /// Whether this platform has a step source to correlate against at all.
  final bool hasHealth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool hasPremium = ref.watch(hasPremiumProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                l10n.insightsAnalysisTitle,
                style: AppTextStyle.titleMedium,
              ),
            ),
            if (!hasPremium) const PremiumBadge(),
          ],
        ),
        SizedBox(height: SdSpacingConstant.h16),
        if (hasPremium)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ExertionCorrelationBody(result: result),
              if (hasHealth) ...<Widget>[
                SizedBox(height: SdContentPaddingV2.sectionGap),
                const StepCorrelationBody(),
              ],
            ],
          )
        else
          PremiumUnlockPrompt(message: l10n.premiumLockedSteps),
      ],
    );
  }
}
