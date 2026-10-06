part of 'risk_score_card.dart';

/// Today's number and the word for it, right-aligned beside the title.
class _TodayBadge extends StatelessWidget {
  const _TodayBadge({required this.today});

  final DailyRisk today;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Color color = RiskBandStyle.color(today.band);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        // The percent sign is the point: a bare "62" beside a word reads as a rating out of ten as easily as a probability.
        Text(
          l10n.riskPercent(today.score),
          style: AppTextStyle.titleLarge.copyWith(color: color),
        ),
        Text(
          RiskBandStyle.label(today.band, l10n),
          style: AppTextStyle.labelSmall.copyWith(color: color),
        ),
      ],
    );
  }
}

/// The week's shape: seven bare bars, band-coloured, today at full strength. No numbers — those are on the screen the card opens.
class _MiniWeek extends StatelessWidget {
  const _MiniWeek({required this.days});

  final List<DailyRisk> days;

  /// The bar a 100% day would draw.
  static double get _maxBar => SdSpacingConstant.h24;

  /// The other days step back, so the eye starts on today.
  static const double _restAlpha = 0.45;

  @override
  Widget build(BuildContext context) {
    // The screen reads every day out; here the bars would be seven unlabelled shapes to a screen reader.
    return ExcludeSemantics(
      child: SizedBox(
        height: _maxBar,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            for (final (int index, DailyRisk day) in days.indexed) ...<Widget>[
              if (index > 0) SizedBox(width: SdSpacingConstant.w4),
              Expanded(
                child: Container(
                  height: _maxBar * (day.score / 100).clamp(0.12, 1),
                  decoration: BoxDecoration(
                    color: RiskBandStyle.color(
                      day.band,
                    ).withValues(alpha: index == 0 ? 1 : _restAlpha),
                    borderRadius: BorderRadius.circular(SdSpacingConstant.r4),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
