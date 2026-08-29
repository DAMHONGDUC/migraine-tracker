import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../core/constants/calendar_constant.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icon_constant.dart';
import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/utils/date_time_utils.dart';

/// A month calendar that shows the whole picked window, not just one day.
class DateRangeCalendar extends StatefulWidget {
  const DateRangeCalendar({
    required this.from,
    required this.to,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
    this.initialMonth,
    super.key,
  });

  /// Diameter of a day's disc. The band behind it fills the whole cell.
  static double get daySize => SdSpacingConstant.r36;

  /// Start of the window, or null for "any".
  final DateTime? from;

  /// End of the window, or null for "any".
  final DateTime? to;

  /// Oldest and newest selectable days, both inclusive. Days outside them are shown greyed rather than hidden, so the month keeps its shape.
  final DateTime firstDate;
  final DateTime lastDate;

  final ValueChanged<DateTime> onDateSelected;

  /// Month the calendar opens on. Defaults to [lastDate]'s month.
  final DateTime? initialMonth;

  @override
  State<DateRangeCalendar> createState() => _DateRangeCalendarState();
}

class _DateRangeCalendarState extends State<DateRangeCalendar> {
  late DateTime _month = DateTimeUtils.monthOf(widget.initialMonth ?? widget.lastDate);

  void _showMonth(int delta) {
    setState(() {
      _month = DateUtils.addMonthsToMonthDate(_month, delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final DateTime firstMonth = DateTimeUtils.monthOf(widget.firstDate);
    final DateTime lastMonth = DateTimeUtils.monthOf(widget.lastDate);

    return Column(
      children: <Widget>[
        _MonthHeader(
          month: _month,
          onPrevious: _month.isAfter(firstMonth) ? () => _showMonth(-1) : null,
          onNext: _month.isBefore(lastMonth) ? () => _showMonth(1) : null,
        ),
        SizedBox(height: SdSpacingConstant.h8),
        const _WeekdayLabels(),
        SizedBox(height: SdSpacingConstant.h4),
        _MonthGrid(
          month: _month,
          from: widget.from,
          to: widget.to,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          onDateSelected: widget.onDateSelected,
        ),
      ],
    );
  }
}

/// Month name with an arrow either side; an arrow disabled at the bounds.
class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations material = MaterialLocalizations.of(context);
    final String title = DateFormat.yMMMM(
      context.l10n.localeName,
    ).format(month);

    return Row(
      children: <Widget>[
        IconButton(
          onPressed: onPrevious,
          tooltip: material.previousMonthTooltip,
          icon: SdIconV2(icon: AppIconConstant.previous, size: AppIconSize.medium),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyle.titleSmall,
          ),
        ),
        IconButton(
          onPressed: onNext,
          tooltip: material.nextMonthTooltip,
          icon: SdIconV2(
            icon: AppIconConstant.disclosure,
            size: AppIconSize.medium,
          ),
        ),
      ],
    );
  }
}

/// The weekday initials, in the locale's own week order.
class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels();

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations material = MaterialLocalizations.of(context);
    final List<Widget> labels = <Widget>[];

    for (int i = 0; i < CalendarConstant.daysPerWeek; i++) {
      final int weekday =
          (material.firstDayOfWeekIndex + i) % CalendarConstant.daysPerWeek;

      labels.add(
        Expanded(
          child: Text(
            material.narrowWeekdays[weekday],
            textAlign: TextAlign.center,
            style: AppTextStyle.labelSmall.secondary,
          ),
        ),
      );
    }

    return Row(children: labels);
  }
}

/// The month's days, laid out seven to a row.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.from,
    required this.to,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
  });

  final DateTime month;
  final DateTime? from;
  final DateTime? to;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations material = MaterialLocalizations.of(context);
    final int leadingBlanks = DateUtils.firstDayOffset(
      month.year,
      month.month,
      material,
    );
    final int daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final DateTime? start = from == null ? null : DateUtils.dateOnly(from!);
    final DateTime? end = to == null ? null : DateUtils.dateOnly(to!);
    final bool hasRange =
        start != null && end != null && !DateUtils.isSameDay(start, end);
    final List<Widget> cells = <Widget>[];

    for (
      int i = 0;
      i < CalendarConstant.weekRows * CalendarConstant.daysPerWeek;
      i++
    ) {
      final int day = i - leadingBlanks + 1;

      if (day < 1 || day > daysInMonth) {
        cells.add(const SizedBox.shrink());
        continue;
      }

      final DateTime date = DateTime(month.year, month.month, day);
      final bool isStart = start != null && DateUtils.isSameDay(date, start);
      final bool isEnd = end != null && DateUtils.isSameDay(date, end);
      final bool isInside =
          hasRange && date.isAfter(start) && date.isBefore(end);

      cells.add(
        _DayCell(
          date: date,
          isSelected: isStart || isEnd,
          isToday: DateUtils.isSameDay(date, DateTime.now()),
          isEnabled:
              !date.isBefore(DateUtils.dateOnly(firstDate)) &&
              !date.isAfter(DateUtils.dateOnly(lastDate)),
          onTap: () => onDateSelected(date),
          // A day between the two ends bands both sides so the row reads as one block.
          bandBefore: hasRange && (isEnd || isInside),
          bandAfter: hasRange && (isStart || isInside),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisCount: CalendarConstant.daysPerWeek,
      children: cells,
    );
  }
}

/// One day: the band it sits on, its disc, and its number.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.bandBefore,
    required this.bandAfter,
    required this.isToday,
    required this.isEnabled,
    required this.onTap,
  });

  /// Tint of the days between the two ends — the picked bound tile's fill, a touch stronger so a whole cell of it still reads as one block.
  static Color get bandColor => AppColors.primary.withValues(alpha: 0.18);

  final DateTime date;
  final bool isSelected;
  final bool bandBefore;
  final bool bandAfter;
  final bool isToday;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor = switch (<bool>[isSelected, isEnabled]) {
      [true, _] => AppColors.onPrimary,
      [_, false] => AppColors.textSecondary.withValues(alpha: 0.35),
      // In-range days are carried by the band behind them, so the number stays plain.
      _ => isToday ? AppColors.primary : AppColors.textPrimary,
    };
    final TextStyle style = isSelected || isToday
        ? AppTextStyle.bodyMedium.w600.copyWith(color: textColor)
        : AppTextStyle.bodyMedium.copyWith(color: textColor);

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkResponse(
        onTap: isEnabled ? onTap : null,
        radius: DateRangeCalendar.daySize / 2,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // Fills the cell, so consecutive days read as one solid block, not a thin stripe.
            Positioned.fill(
              child: Row(
                // Stretch, or a childless ColoredBox takes zero height and the band never draws.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: ColoredBox(
                      color: bandBefore ? bandColor : AppColors.transparent,
                    ),
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: bandAfter ? bandColor : AppColors.transparent,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: DateRangeCalendar.daySize,
              height: DateRangeCalendar.daySize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : AppColors.transparent,
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.primary)
                    : null,
              ),
              child: Text(
                DateFormat.d(context.l10n.localeName).format(date),
                style: style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
