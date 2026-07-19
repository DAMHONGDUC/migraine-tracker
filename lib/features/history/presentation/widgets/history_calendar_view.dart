import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../domain/services/attacks_by_day.dart';
import 'attack_tile.dart';

/// Month calendar: each day with attacks is dotted in its **worst**
/// intensity's severity colour; tapping a day lists that day's attacks
/// below. Owns its month navigation, so the period filter is hidden in this
/// mode (see HistoryScreen).
class HistoryCalendarView extends HookWidget {
  const HistoryCalendarView({required this.attacks, super.key});

  final List<Attack> attacks;

  @override
  Widget build(BuildContext context) {
    final byDay = attacksByDay(attacks);
    final today = dayKey(DateTime.now());
    final selected = useState(today);
    final focused = useState(today);

    final selectedAttacks = byDay[selected.value] ?? const <Attack>[];

    return ListView(
      padding: EdgeInsets.all(AppSpacingConstant.w16),
      children: [
        TableCalendar<Attack>(
          firstDay: DateTime(2020),
          lastDay: DateTime(today.year + 1, 12, 31),
          focusedDay: focused.value,
          currentDay: today,
          startingDayOfWeek: StartingDayOfWeek.monday,
          locale: context.l10n.localeName,
          selectedDayPredicate: (day) => isSameDay(day, selected.value),
          eventLoader: (day) => byDay[dayKey(day)] ?? const [],
          onDaySelected: (selectedDay, focusedDay) {
            selected.value = dayKey(selectedDay);
            focused.value = focusedDay;
          },
          onPageChanged: (focusedDay) => focused.value = focusedDay,
          availableCalendarFormats: const {CalendarFormat.month: ''},
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: context.textTheme.titleMedium ?? const TextStyle(),
            leftChevronIcon: const Icon(Icons.chevron_left),
            rightChevronIcon: const Icon(Icons.chevron_right),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            defaultTextStyle: context.textTheme.bodyMedium ?? const TextStyle(),
            weekendTextStyle: context.textTheme.bodyMedium ?? const TextStyle(),
            todayDecoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: context.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            todayTextStyle: context.textTheme.bodyMedium ?? const TextStyle(),
            selectedDecoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colorScheme.primary.withValues(alpha: 0.28),
            ),
            selectedTextStyle:
                context.textTheme.bodyMedium ?? const TextStyle(),
          ),
          calendarBuilders: CalendarBuilders<Attack>(
            markerBuilder: (context, day, events) {
              final peak = peakIntensity(events);
              if (peak == null) return null;
              return Container(
                width: AppSpacingConstant.r6,
                height: AppSpacingConstant.r6,
                margin: EdgeInsets.only(bottom: AppSpacingConstant.h4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.intensity(peak),
                ),
              );
            },
          ),
        ),
        SizedBox(height: AppSpacingConstant.h8),
        Text(
          context.l10n.historyCalendarLegend,
          textAlign: TextAlign.center,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: AppSpacingConstant.h16),
        if (selectedAttacks.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacingConstant.h16),
            child: Text(
              context.l10n.historyCalendarNoAttacks,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final attack in selectedAttacks) ...[
            AttackTile(attack: attack),
            SizedBox(height: AppSpacingConstant.h8),
          ],
      ],
    );
  }
}
