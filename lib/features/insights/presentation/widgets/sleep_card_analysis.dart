part of 'sleep_card.dart';

/// The premium half: whether attacks follow short nights.
///
/// Free users get one line and an Unlock button, no blurred sample — same
/// call as [ActivityCard]'s analysis.
class _Analysis extends ConsumerWidget {
  const _Analysis();

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
          const SleepCorrelationBody()
        else
          PremiumUnlockPrompt(message: l10n.premiumLockedSleep),
      ],
    );
  }
}
