import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../domain/services/attacks_by_day.dart';
import 'attack_tile.dart';

/// Month calendar: each day with attacks is dotted in its **worst**
/// intensity's severity colour; tapping a day lists that day's attacks
/// below. Owns its month navigation, so the period filter is hidden in this
/// mode (see HistoryScreen).
///
/// The calendar sits ABOVE the day list (not inside its scroll view):
/// scrolling the list collapses it to a compact strip — weekday labels +
/// the selected week, month-title header hidden. It stays collapsed until
/// the user deliberately expands it: a pull past the top of the list, or a
/// swipe down on the strip itself. Because the list starts right under the
/// calendar box and the height change is a single animation, there is
/// never a dead gap between the strip and the first tile.
class HistoryCalendarView extends HookWidget {
  const HistoryCalendarView({
    required this.attacks,
    required this.topInset,
    required this.bottomInset,
    super.key,
  });

  final List<Attack> attacks;

  /// Bar clearances, computed by the parent from a context inside the
  /// Scaffold body (where MediaQuery reports the real bar heights).
  final double topInset;
  final double bottomInset;

  static const _grouper = AttacksByDayGrouper();

  @override
  Widget build(BuildContext context) {
    final byDay = _grouper.groupByDay(attacks);
    final today = _grouper.dayKey(DateTime.now());
    final selected = useState(today);
    final focused = useState(today);
    final collapsed = useState(false);
    final scrollController = useScrollController();

    // Collapse once the list is meaningfully scrolled. Expanding is never
    // automatic — merely returning to the top keeps the strip compact; the
    // user expands it deliberately (pull past the top, or swipe down on
    // the strip itself via onFormatChanged below).
    useEffect(() {
      void onScroll() {
        if (!collapsed.value &&
            scrollController.offset > AppSpacingConstant.h32) {
          collapsed.value = true;
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    // A drag past the top edge re-expands the calendar. dragDetails filters
    // out ballistic bounces: only a finger actually pulling counts, so a
    // fling that overshoots the top doesn't pop the month grid open.
    bool onScrollNotification(ScrollNotification notification) {
      if (!collapsed.value) return false;
      final pulling = switch (notification) {
        OverscrollNotification(:final dragDetails, :final overscroll) =>
          dragDetails != null && overscroll < 0,
        ScrollUpdateNotification(:final dragDetails, :final metrics) =>
          dragDetails != null && metrics.pixels < -AppSpacingConstant.h8,
        _ => false,
      };
      if (pulling) collapsed.value = false;
      return false;
    }

    final selectedAttacks = byDay[selected.value] ?? const <Attack>[];

    final daysOfWeekH = AppSpacingConstant.h20;
    final rowH = AppSpacingConstant.h44;

    // Top inset lives OUTSIDE the scroll view: the calendar must sit below
    // the app bar, never slide behind it.
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacingConstant.w16,
        right: AppSpacingConstant.w16,
        top: topInset,
      ),
      child: Column(
        children: [
          // Calm height animation between month grid and week strip (hard
          // rule 3: nothing flashy). ClipRect keeps the mid-animation
          // overflow invisible.
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: TableCalendar<Attack>(
                firstDay: DateTime(2020),
                lastDay: DateTime(today.year + 1, 12, 31),
                focusedDay: focused.value,
                currentDay: today,
                startingDayOfWeek: StartingDayOfWeek.monday,
                locale: context.l10n.localeName,
                calendarFormat: collapsed.value
                    ? CalendarFormat.week
                    : CalendarFormat.month,
                // The collapsed strip drops the month-title header too:
                // just the weekday labels and the selected week.
                headerVisible: !collapsed.value,
                rowHeight: rowH,
                daysOfWeekHeight: daysOfWeekH,
                selectedDayPredicate: (day) => isSameDay(day, selected.value),
                eventLoader: (day) => byDay[_grouper.dayKey(day)] ?? const [],
                onDaySelected: (selectedDay, focusedDay) {
                  selected.value = _grouper.dayKey(selectedDay);
                  focused.value = focusedDay;
                },
                onPageChanged: (focusedDay) => focused.value = focusedDay,
                // Vertical swipe on the calendar itself: down expands to
                // the month grid, up collapses to the week strip.
                onFormatChanged: (format) =>
                    collapsed.value = format == CalendarFormat.week,
                availableCalendarFormats: const {
                  CalendarFormat.month: '',
                  CalendarFormat.week: '',
                },
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: AppTextStyle.titleMedium,
                  leftChevronIcon: const Icon(Icons.chevron_left),
                  rightChevronIcon: const Icon(Icons.chevron_right),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle: AppTextStyle.bodyMedium,
                  weekendTextStyle: AppTextStyle.bodyMedium,
                  todayDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
                  todayTextStyle: AppTextStyle.bodyMedium,
                  selectedDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colorScheme.primary.withValues(alpha: 0.28),
                  ),
                  selectedTextStyle: AppTextStyle.bodyMedium,
                ),
                calendarBuilders: CalendarBuilders<Attack>(
                  markerBuilder: (context, day, events) {
                    final peak = _grouper.peakIntensity(events);
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
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: onScrollNotification,
              child: ListView(
                controller: scrollController,
                // No ambient MediaQuery padding: the app bar clearance is
                // already handled by topInset above the calendar, and the
                // bottom nav by the trailing SizedBox — the default would
                // open a dead gap between the calendar and the legend.
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: AppSpacingConstant.h8),
                    child: Text(
                      context.l10n.historyCalendarLegend,
                      textAlign: TextAlign.center,
                      style: AppTextStyle.bodySmall.secondary,
                    ),
                  ),
                  SizedBox(height: AppSpacingConstant.h8),
                  if (selectedAttacks.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacingConstant.h16,
                      ),
                      child: Text(
                        context.l10n.historyCalendarNoAttacks,
                        textAlign: TextAlign.center,
                        style: AppTextStyle.bodyMedium.secondary,
                      ),
                    )
                  else
                    for (final (i, attack) in selectedAttacks.indexed) ...[
                      if (i > 0) SizedBox(height: AppSpacingConstant.h8),
                      AttackTile(attack: attack),
                    ],
                  // Clearance so the last tile scrolls past the floating
                  // glass nav.
                  SizedBox(height: bottomInset + AppSpacingConstant.h16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
