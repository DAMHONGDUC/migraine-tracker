part of 'weather_card.dart';

/// The week across the top: seven cells sharing the card's width, no
/// scrolling.
///
/// A `Row` of `Expanded`, not a horizontal `ListView`: a week is a fixed,
/// small number and it fits, so a scroll gesture here would hide days behind
/// an edge for no reason. That is also what makes every cell the same width
/// whatever its label.
class _DayStrip extends ConsumerWidget {
  const _DayStrip({required this.week, required this.selected});

  final List<WeatherDaily> week;
  final int selected;

  /// Tight, because seven cells share ~321pt at the design width and the
  /// gaps come out of the same budget as the labels.
  static double get gap => SdSpacingConstant.w4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // IntrinsicHeight, and it is not optional: `stretch` tells a Row its
    // children must fill the cross axis, and inside a Column in a ListView
    // that axis is unbounded — which asserts "BoxConstraints forces an
    // infinite height" on every frame and takes the whole screen with it.
    // This bounds the height to the tallest cell first, so stretch has
    // something finite to match, and every cell comes out that height.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final (int index, WeatherDaily day) in week.indexed) ...<Widget>[
            if (index > 0) SizedBox(width: gap),
            Expanded(
              child: _DayCell(
                day: day,
                isToday: index == 0,
                isSelected: index == selected,
                onTap: () => ref.read(weatherDayProvider.notifier).set(index),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One day: the weekday, its glyph, its high.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final WeatherDaily day;

  /// Today is named by its own weekday like every other cell — "Today" and
  /// "Hôm nay" are both too wide for a seventh of the card. What marks it is
  /// the accent on the label, which costs no width at all.
  final bool isToday;

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final String? high = WeatherConditionUtils.temperature(
      l10n,
      day.temperatureMaxCelsius,
    );
    final Color labelColour = isSelected || isToday
        ? context.colorScheme.primary
        : AppColors.textSecondary;

    return SdPressableScaleV2(
      pressedScale: 0.96,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: SdSpacingConstant.h8,
          horizontal: SdSpacingConstant.w2,
        ),
        decoration: BoxDecoration(
          // Filled when picked; a step up from the card otherwise, like
          // everything else that sits on one.
          color: isSelected
              ? context.colorScheme.primary.withValues(alpha: 0.18)
              : context.sdTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(SdSpacingConstant.r12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              DateFormat.E(l10n.localeName).format(day.date.toLocal()),
              style: AppTextStyle.bodySmall.copyWith(
                color: labelColour,
                fontWeight: isSelected || isToday
                    ? FontWeight.w600
                    : FontWeight.w400,
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
              style: AppTextStyle.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
