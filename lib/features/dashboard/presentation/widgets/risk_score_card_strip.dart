part of 'risk_score_card.dart';

/// The colour a band is drawn in, in one place so the number and its bar can never disagree.
Color _bandColor(RiskBand band) => switch (band) {
  RiskBand.low => AppColors.primary,
  RiskBand.moderate => AppColors.intensity(5),
  RiskBand.high => AppColors.intensity(9),
};

String _bandLabel(RiskBand band, AppLocalizations l10n) => switch (band) {
  RiskBand.low => l10n.riskBandLow,
  RiskBand.moderate => l10n.riskBandModerate,
  RiskBand.high => l10n.riskBandHigh,
};

/// Today's number and the word for it.
class _TodayScore extends StatelessWidget {
  const _TodayScore({required this.today});

  final DailyRisk today;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Color color = _bandColor(today.band);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Text(
          '${today.score}',
          style: AppTextStyle.displaySmall.copyWith(color: color),
        ),
        SizedBox(width: SdSpacingConstant.w8),
        Text(
          _bandLabel(today.band, l10n),
          style: AppTextStyle.titleSmall.copyWith(color: color),
        ),
      ],
    );
  }
}

/// Seven bars, today first. A bar rather than a number each: what a glance is for is which day stands out.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.days});

  final List<DailyRisk> days;

  /// The tallest a bar gets. Its own intrinsic size, not configuration about it.
  static const double barHeight = 40;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateFormat weekday = DateFormat.E(
      Localizations.localeOf(context).toLanguageTag(),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        for (final (int index, DailyRisk day) in days.indexed) ...<Widget>[
          if (index > 0) SizedBox(width: SdSpacingConstant.w8),
          Expanded(
            child: Semantics(
              label: '${_bandLabel(day.band, l10n)} ${day.score}',
              excludeSemantics: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    height: barHeight,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        // A floor of a tenth, so a zero day still draws a bar rather than a gap the eye reads as missing data.
                        height: barHeight * (day.score.clamp(10, 100) / 100),
                        decoration: BoxDecoration(
                          color: _bandColor(day.band),
                          borderRadius: BorderRadius.circular(
                            SdSpacingConstant.r4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: SdSpacingConstant.h4),
                  Text(
                    index == 0 ? l10n.riskToday : weekday.format(day.day),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The working: every signal that scored today, and every one that could not be read.
class _Reasons extends StatelessWidget {
  const _Reasons({required this.today});

  final DailyRisk today;

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
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}
