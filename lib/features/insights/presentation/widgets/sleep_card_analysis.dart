part of 'sleep_card.dart';

/// The premium half: whether attacks follow short nights.
///
/// Free users see the shape of it blurred, drawn from the sample nights, not
/// their own — same rule as [ActivityCard]'s analysis.
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
          PremiumChartLock(
            sample: SleepCorrelationBody(
              result: ref.watch(sampleSleepCorrelationProvider),
            ),
          ),
      ],
    );
  }
}
