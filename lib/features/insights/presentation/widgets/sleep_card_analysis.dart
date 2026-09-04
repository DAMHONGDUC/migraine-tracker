part of 'sleep_card.dart';

/// The premium half: whether attacks follow short nights.
class _Analysis extends ConsumerWidget {
  const _Analysis();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    if (!ref.watch(hasPremiumProvider)) {
      return InsightCard(
        title: l10n.insightsAnalysisTitle,
        trailing: const PremiumBadge(),
        child: PremiumUnlockPrompt(message: l10n.premiumLockedSleep),
      );
    }

    return InsightCard(
      title: l10n.insightsSleepTitle,
      onInfo: () => AnalysisInfoSheet(
        title: l10n.insightsSleepTitle,
        paragraphs: <String>[
          l10n.insightsExplainSleep1,
          l10n.insightsExplainSleep2,
          l10n.insightsExplainSleep3,
        ],
      ).show(context),
      child: const SleepCorrelationBody(),
    );
  }
}
