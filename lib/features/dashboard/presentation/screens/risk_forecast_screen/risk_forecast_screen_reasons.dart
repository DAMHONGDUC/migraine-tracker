part of 'risk_forecast_screen.dart';

/// The working: every signal that scored today, and every one that could not be read.
class _Reasons extends StatelessWidget {
  const _Reasons({required this.today});

  final DailyRisk today;

  /// Whether there is anything to list — the screen drops the card rather than draw a heading over nothing.
  static bool hasAny(DailyRisk today) =>
      today.missing.isNotEmpty ||
      today.contributions.any(
        (RiskContribution c) => c.isAvailable && c.points > 0,
      );

  /// Only what actually moved the score. A signal that read zero is true and says nothing.
  String? _line(RiskContribution c, AppLocalizations l10n) {
    if (!c.isAvailable || c.points <= 0) return null;
    return switch (c.signal) {
      // The string already says "falling", so the number is the size of the fall and takes no sign of its own.
      RiskSignal.pressureDrop => l10n.riskSignalPressure(
        (c.dropHpa ?? 0).toStringAsFixed(1),
      ),
      RiskSignal.cycleWindow => l10n.riskSignalCycle,
      RiskSignal.sleepDebt => l10n.riskSignalSleep(c.sleepDebtMinutes ?? 0),
      RiskSignal.recentFrequency => l10n.riskSignalFrequency(
        c.recentAttacks ?? 0,
      ),
    };
  }

  String _missingLabel(RiskSignal signal, AppLocalizations l10n) =>
      switch (signal) {
        RiskSignal.pressureDrop => l10n.riskMissingPressure,
        RiskSignal.cycleWindow => l10n.riskMissingCycle,
        RiskSignal.sleepDebt => l10n.riskMissingSleep,
        RiskSignal.recentFrequency => l10n.riskMissingFrequency,
      };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<String> lines = <String>[
      for (final RiskContribution c in today.contributions)
        if (_line(c, l10n) case final String line) line,
    ];
    // Today's own gaps only. Tomorrow has no sleep reading by construction, and saying so seven times would be noise.
    final List<RiskSignal> missing = today.missing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(l10n.riskReasonsTitle, style: AppTextStyle.titleSmall),
        SizedBox(height: SdSpacingConstant.h8),
        for (final String line in lines)
          Padding(
            padding: EdgeInsets.only(bottom: SdSpacingConstant.h4),
            child: Text(line, style: AppTextStyle.bodySmall),
          ),
        if (missing.isNotEmpty)
          Text(
            l10n.riskMissing(
              <String>[
                for (final RiskSignal signal in missing)
                  _missingLabel(signal, l10n),
              ].join(', '),
            ),
            style: AppTextStyle.bodySmall.secondary,
          ),
      ],
    );
  }
}
