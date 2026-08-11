part of 'weather_card.dart';

/// The week across the top: one cell a day, scrolling sideways, the picked
/// one filled.
class _DayStrip extends ConsumerWidget {
  const _DayStrip({required this.week, required this.selected});

  final List<WeatherDaily> week;
  final int selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: _DayCell.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: week.length,
        separatorBuilder: (_, _) => SizedBox(width: SdSpacingConstant.w8),
        itemBuilder: (BuildContext context, int index) => _DayCell(
          day: week[index],
          isToday: index == 0,
          isSelected: index == selected,
          onTap: () => ref.read(weatherDayProvider.notifier).set(index),
        ),
      ),
    );
  }
}

/// One day: the weekday, its glyph, and its high.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final WeatherDaily day;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  /// Stated outright, like the details grid learned to: the strip is inside a
  /// horizontal `ListView`, which gives its children unbounded height, so
  /// nothing else here would size them.
  static double get height =>
      SdSpacingConstant.h8 * 2 +
      SdSpacingConstant.h16 +
      SdSpacingConstant.h4 +
      SdSpacingConstant.r20 +
      SdSpacingConstant.h4 +
      SdSpacingConstant.h20;

  /// Wide enough for a weekday abbreviation in either locale.
  static double get width => SdSpacingConstant.w56;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String? high = WeatherConditionUtils.temperature(
      l10n,
      day.temperatureMaxCelsius,
    );

    return SdPressableScaleV2(
      pressedScale: 0.96,
      onTap: onTap,
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h8),
        decoration: BoxDecoration(
          // Filled when picked; a step up from the card otherwise, like
          // everything else that sits on one.
          color: isSelected
              ? context.colorScheme.primary.withValues(alpha: 0.18)
              : context.sdTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(SdSpacingConstant.r12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              isToday
                  ? l10n.weatherToday
                  : DateFormat.E(l10n.localeName).format(day.date.toLocal()),
              style: AppTextStyle.bodySmall.copyWith(
                color: isSelected
                    ? context.colorScheme.primary
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: SdSpacingConstant.h4),
            SdIconV2(
              icon: WeatherConditionUtils.icon(day.condition),
              size: SdSpacingConstant.r20,
              color: isSelected
                  ? context.colorScheme.primary
                  : AppColors.textSecondary,
            ),
            SizedBox(height: SdSpacingConstant.h4),
            Text(
              high ?? '',
              style: AppTextStyle.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
