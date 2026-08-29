part of 'weather_card.dart';

/// How much rain the next ten days bring, one row a day — the sheet's own half of the card.
class _RainfallForecast extends StatelessWidget {
  const _RainfallForecast({
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
        Text(
          // The count comes from the constant that decides it, never a number typed into the ARB — one of them would go stale.
          context.l10n.weatherRainfallTitle(WeatherReport.forecastDayCount),
          style: AppTextStyle.titleSmall,
        ),
        SizedBox(height: SdSpacingConstant.h8),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: days.length,
            // Between rows only, which is what `separated` means — a rule above the first would sit on the gap under the heading.
            separatorBuilder: (_, _) => const SdDividerV2(),
            itemBuilder: (BuildContext context, int index) => _DayRow(
              day: days[index],
              isToday: index == 0,
              isSelected: index == selected,
              onTap: () => onSelected(index),
            ),
          ),
        ),
      ],
    );
  }
}

/// One day: what it is called, what the sky does, how likely rain is and how much of it falls.
class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final WeatherDaily day;

  /// Today is named "Today" here, where the row is a full width wide.
  final bool isToday;

  final bool isSelected;
  final VoidCallback onTap;

  /// How far the selected row's fill is tinted. Low, per hard rule 3 — the mark has to be findable without being a highlight.
  static const double selectedTint = 0.14;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String? chance = day.precipitationChancePercent == null
        ? null
        : l10n.weatherPercent(day.precipitationChancePercent!.round());
    final String? amount = day.precipitationAmountMm == null
        ? null
        // One decimal, as everywhere else rain is printed: a day of drizzle is 0.4mm, and rounded to whole millimetres it reads as no rain.
        : l10n.weatherMillimetreValue(
            day.precipitationAmountMm!.toStringAsFixed(1),
          );

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
                    : DateFormat.EEEE(
                        l10n.localeName,
                      ).format(day.date.toLocal()),
                style: isToday
                    ? AppTextStyle.bodyMedium.w600
                    : AppTextStyle.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SdIconV2(
              icon: WeatherConditionUtils.icon(day.condition),
              size: AppIconSize.medium,
              color: AppColors.primary,
            ),
            // Beside the glyph it belongs to, and only where Apple gave a figure — a dash here would be a forecast the app invented.
            SizedBox(
              width: SdSpacingConstant.w40,
              child: chance == null
                  ? null
                  : Text(
                      chance,
                      style: AppTextStyle.bodySmall.secondary,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                    ),
            ),
            SizedBox(width: SdSpacingConstant.w8),
            // The reading this list is named after, so it ends the row and carries the row's own weight of type.
            Expanded(
              flex: 3,
              child: Text(
                amount ?? '—',
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
}
