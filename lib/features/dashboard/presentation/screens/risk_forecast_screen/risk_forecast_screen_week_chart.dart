part of 'risk_forecast_screen.dart';

/// The seven days as a strip of columns, today first: percentage, bar, weekday.
///
/// **Columns, each with its number written on top** (owner's call, 2026-09-30
/// redesign). Rows answered "how likely is Thursday" but took seven lines; bare
/// bars could be compared and never read. A column carrying its own percentage
/// does both.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.days});

  final List<DailyRisk> days;

  /// The bar a 100% day would draw. Everything else is a share of it.
  static double get _maxBar => SdSpacingConstant.h56;

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
          if (index > 0) SizedBox(width: SdSpacingConstant.w4),
          Expanded(
            child: Semantics(
              label:
                  '${index == 0 ? l10n.riskToday : weekday.format(day.day)} '
                  '${RiskBandStyle.label(day.band, l10n)} ${l10n.riskPercent(day.score)}',
              excludeSemantics: true,
              child: _DayColumn(
                label: index == 0 ? l10n.riskToday : weekday.format(day.day),
                value: l10n.riskPercent(day.score),
                barHeight: _maxBar * (day.score / 100).clamp(0.06, 1),
                color: RiskBandStyle.color(day.band),
                isToday: index == 0,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// One day of the strip. Today sits on a raised well, so the eye starts there.
class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.label,
    required this.value,
    required this.barHeight,
    required this.color,
    required this.isToday,
  });

  final String label;
  final String value;
  final double barHeight;
  final Color color;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h8),
      decoration: BoxDecoration(
        color: isToday ? context.sdTheme.surfaceModal : null,
        borderRadius: BorderRadius.circular(SdSpacingConstant.r12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SdFittedTextV2(
            value,
            maxLines: 1,
            style: AppTextStyle.labelSmall.w600,
          ),
          SizedBox(height: SdSpacingConstant.h4),
          Container(
            width: SdSpacingConstant.w14,
            height: barHeight,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(SdSpacingConstant.r4),
            ),
          ),
          SizedBox(height: SdSpacingConstant.h4),
          SdFittedTextV2(
            label,
            maxLines: 1,
            style: isToday
                ? AppTextStyle.labelSmall
                : AppTextStyle.labelSmall.secondary,
          ),
        ],
      ),
    );
  }
}
