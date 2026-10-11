part of 'sleep_card.dart';

/// The analysis half: whether attacks follow short nights.
class _Analysis extends StatelessWidget {
  const _Analysis();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

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
