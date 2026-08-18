part of 'weather_card.dart';

/// The week ahead, one row a day — the sheet's own half of the card.
///
/// **A `Column`, not a `ListView`.** Seven rows is a fixed, small number and
/// the sheet already scrolls; a scroll view inside a scroll view would need
/// `shrinkWrap` and give the sheet two places to put a scrollbar.
///
/// This is what the retired Insights weather card's day strip used to be, at
/// the size a sheet allows: seven cells sharing a card's width could only fit
/// a weekday, a glyph and one temperature, so the low was dropped and the
/// chance of rain never appeared at all.
class _WeekForecast extends StatelessWidget {
  const _WeekForecast({
    required this.days,
    required this.selected,
    required this.onSelected,
  });

  final List<WeatherDaily> days;

  /// Index into [days] of the day the readings above are describing.
  final int selected;

  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(context.l10n.weatherWeekTitle, style: AppTextStyle.titleSmall),
        SizedBox(height: SdSpacingConstant.h8),
        for (final (int index, WeatherDaily day) in days.indexed) ...<Widget>[
          // Between rows only — a rule above the first would sit on the gap
          // that separates this block from the grid above it.
          if (index > 0) const SdDividerV2(),
          _DayRow(
            day: day,
            isToday: index == 0,
            isSelected: index == selected,
            onTap: () => onSelected(index),
          ),
        ],
      ],
    );
  }
}

/// One day: what it is called, what the sky does, how likely rain is, and the
/// two temperatures it runs between.
///
/// **Tappable, and that is what makes the sheet worth scrolling** (owner's
/// call): picking a day re-reads the grid above it — wind, UV, the sun's
/// hours, the pressure — against that day rather than against right now.
///
/// The selected row is marked by a tinted fill, not by a colour on its text:
/// the row already spends colour on the condition glyph, and a second accent
/// inside it would leave nothing saying which of the two means "picked".
class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final WeatherDaily day;

  /// Today is named "Today" here, where the row is a full width wide. The old
  /// day strip could not — "Hôm nay" does not fit a seventh of a card — and
  /// marked it with an accent instead.
  final bool isToday;

  final bool isSelected;
  final VoidCallback onTap;

  /// How far the selected row's fill is tinted. Low, per hard rule 3 — the
  /// mark has to be findable without being a highlight.
  static const double selectedTint = 0.14;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String? rain = day.precipitationChancePercent == null
        ? null
        : l10n.weatherPercent(day.precipitationChancePercent!.round());

    return SdPressableScaleV2(
      pressedScale: 0.99,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: selectedTint)
              : null,
          borderRadius: BorderRadius.circular(SdSpacingConstant.r12),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: SdSpacingConstant.w8,
          vertical: SdSpacingConstant.h8,
        ),
        child: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Text(
              isToday
                  ? l10n.weatherToday
                  : DateFormat.EEEE(l10n.localeName).format(day.date.toLocal()),
              style: isToday
                  ? AppTextStyle.bodyMedium.w600
                  : AppTextStyle.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SdIconV2(
            icon: WeatherConditionUtils.icon(day.condition),
            size: SdSpacingConstant.r20,
            color: AppColors.primary,
          ),
          // Beside the glyph it belongs to, and only where Apple gave a
          // figure — a dash here would be a forecast the app invented.
          SizedBox(
            width: SdSpacingConstant.w40,
            child: rain == null
                ? null
                : Text(
                    rain,
                    style: AppTextStyle.bodySmall.secondary,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                  ),
          ),
          SizedBox(width: SdSpacingConstant.w8),
          Expanded(
            flex: 3,
            child: Text(
              _range(l10n),
              style: AppTextStyle.bodyMedium,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            ),
          ],
        ),
      ),
    );
  }

  /// "18° / 26°" — low first, the order every forecast states it in. An em
  /// dash stands in for a missing half, because the pair has to keep its
  /// shape or the column stops lining up.
  String _range(AppLocalizations l10n) => l10n.weatherRange(
    WeatherConditionUtils.temperature(l10n, day.temperatureMinCelsius) ?? '—',
    WeatherConditionUtils.temperature(l10n, day.temperatureMaxCelsius) ?? '—',
  );
}
