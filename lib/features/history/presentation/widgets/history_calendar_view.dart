import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../domain/services/attacks_by_day.dart';
import 'attack_tile.dart';

/// Month calendar: each day with attacks is dotted in its **worst**
/// intensity's severity colour; tapping a day lists that day's attacks
/// below. Owns its month navigation, so the period filter is hidden in this
/// mode (see HistoryScreen).
///
/// The calendar lives in a pinned sliver header: scrolling the day list
/// collapses it from month grid to a single week strip (and back at the
/// top), so the list gets the space while the selected week stays visible.
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

    // Fixed calendar metrics so the sliver extents are exact:
    // header (month title + chevrons), weekday row, and 6 date rows
    // (sixWeekMonthsEnforced keeps every month the same height).
    final headerH = AppSpacingConstant.h64;
    final daysOfWeekH = AppSpacingConstant.h20;
    final rowH = AppSpacingConstant.h44;
    final monthExtent = headerH + daysOfWeekH + 6 * rowH;
    final weekExtent = headerH + daysOfWeekH + rowH;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacingConstant.w16),
      child: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _CollapsingCalendarDelegate(
              minExtent: weekExtent,
              maxExtent: monthExtent,
              builder: (context, collapsed) => TableCalendar<Attack>(
                firstDay: DateTime(2020),
                lastDay: DateTime(today.year + 1, 12, 31),
                focusedDay: focused.value,
                currentDay: today,
                startingDayOfWeek: StartingDayOfWeek.monday,
                locale: context.l10n.localeName,
                calendarFormat: collapsed
                    ? CalendarFormat.week
                    : CalendarFormat.month,
                sixWeekMonthsEnforced: true,
                rowHeight: rowH,
                daysOfWeekHeight: daysOfWeekH,
                selectedDayPredicate: (day) => isSameDay(day, selected.value),
                eventLoader: (day) => byDay[dayKey(day)] ?? const [],
                onDaySelected: (selectedDay, focusedDay) {
                  selected.value = dayKey(selectedDay);
                  focused.value = focusedDay;
                },
                onPageChanged: (focusedDay) => focused.value = focusedDay,
                availableCalendarFormats: const {
                  CalendarFormat.month: '',
                  CalendarFormat.week: '',
                },
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle:
                      context.textTheme.titleMedium ?? const TextStyle(),
                  leftChevronIcon: const Icon(Icons.chevron_left),
                  rightChevronIcon: const Icon(Icons.chevron_right),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle:
                      context.textTheme.bodyMedium ?? const TextStyle(),
                  weekendTextStyle:
                      context.textTheme.bodyMedium ?? const TextStyle(),
                  todayDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          context.colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
                  todayTextStyle:
                      context.textTheme.bodyMedium ?? const TextStyle(),
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
                    // The dot is colour-only — give VoiceOver count + peak.
                    return Semantics(
                      label: context.l10n.a11yCalendarMarker(
                        events.length,
                        peak,
                      ),
                      child: Container(
                        width: AppSpacingConstant.r6,
                        height: AppSpacingConstant.r6,
                        margin: EdgeInsets.only(bottom: AppSpacingConstant.h4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.intensity(peak),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: AppSpacingConstant.h8),
              child: Text(
                context.l10n.historyCalendarLegend,
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: AppSpacingConstant.h16),
          ),
          if (selectedAttacks.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsets.symmetric(vertical: AppSpacingConstant.h16),
                child: Text(
                  context.l10n.historyCalendarNoAttacks,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            SliverList.separated(
              itemCount: selectedAttacks.length,
              separatorBuilder: (_, _) =>
                  SizedBox(height: AppSpacingConstant.h8),
              itemBuilder: (context, index) =>
                  AttackTile(attack: selectedAttacks[index]),
            ),
          // Clearance so the last tile scrolls past the floating glass nav.
          SliverToBoxAdapter(
            child: SizedBox(
              height: AppScaffold.bottomNavInset(context) +
                  AppSpacingConstant.h16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pinned header that swaps the calendar between month and week format as it
/// collapses. The child is clipped to the current extent (top-aligned), so
/// the drag reads as the month grid sliding away; past the midpoint the
/// calendar animates itself down to the week strip.
class _CollapsingCalendarDelegate extends SliverPersistentHeaderDelegate {
  const _CollapsingCalendarDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.builder,
  });

  @override
  final double minExtent;
  @override
  final double maxExtent;

  final Widget Function(BuildContext context, bool collapsed) builder;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final collapsed = shrinkOffset > (maxExtent - minExtent) / 2;
    // Opaque so the day list never shows through the pinned strip. The
    // OverflowBox grants slack beyond the sliver extent: the calendar's
    // header has fixed-height internals that don't follow screenutil
    // scaling, so a tight box would overflow by a few px on small scales —
    // any excess is clipped instead.
    return ColoredBox(
      color: AppColors.background,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: maxExtent + AppSpacingConstant.h32,
          child: builder(context, collapsed),
        ),
      ),
    );
  }

  // The builder closure captures live state (selected day, attack map), so
  // every new delegate instance must rebuild — extents alone can't tell.
  @override
  bool shouldRebuild(_CollapsingCalendarDelegate oldDelegate) => true;
}
