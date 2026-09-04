part of 'activity_card.dart';

/// The premium half: how attacks line up with exertion, and with steps — a
/// card each (owner's call).
///
/// They were two sections under one "Analysis" heading, which put a
/// self-reported share and a HealthKit comparison on one surface as if they
/// answered the same question. They do not: one has no baseline and the other
/// has two groups of days, and the explanation behind each says something
/// different.
class _Analysis extends ConsumerWidget {
  const _Analysis({required this.result, required this.hasHealth});

  final ExertionCorrelationResult result;

  /// Whether this platform has a step source to correlate against at all.
  final bool hasHealth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    // ONE pitch for the whole tab when locked, not one per card — the same shape the pressure tab takes.
    if (!ref.watch(hasPremiumProvider)) {
      return InsightCard(
        title: l10n.insightsAnalysisTitle,
        trailing: const PremiumBadge(),
        child: PremiumUnlockPrompt(message: l10n.premiumLockedSteps),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InsightCard(
          title: l10n.insightsExertionTitle,
          onInfo: () => AnalysisInfoSheet(
            title: l10n.insightsExertionTitle,
            paragraphs: <String>[
              l10n.insightsExplainExertion1,
              l10n.insightsExplainExertion2,
              l10n.insightsExplainExertion3,
            ],
          ).show(context),
          child: ExertionCorrelationBody(result: result),
        ),
        if (hasHealth) ...<Widget>[
          SizedBox(height: SdContentPaddingV2.sectionGap),
          InsightCard(
            title: l10n.insightsStepsTitle,
            onInfo: () => AnalysisInfoSheet(
              title: l10n.insightsStepsTitle,
              paragraphs: <String>[
                l10n.insightsExplainSteps1,
                l10n.insightsExplainSteps2,
                l10n.insightsExplainSteps3,
              ],
            ).show(context),
            child: const StepCorrelationBody(),
          ),
        ],
      ],
    );
  }
}
