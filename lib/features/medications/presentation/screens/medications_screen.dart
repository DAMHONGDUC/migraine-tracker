import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';
import 'package:migraine_tracker/core/widgets/spacing/horizontal_spacing.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_filter_sheet.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_time_picker_sheet.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/pinned_filter_bar.dart';
import '../../domain/entities/medication.dart';
import '../../domain/enums/medication_filters.dart';
import '../../domain/repositories/medication_reminder_repository.dart';
import '../../providers.dart';
import '../controllers/medication_filters_controller.dart';
import '../widgets/medication_name_dialog.dart';

String _dateFilterLabel(BuildContext context, MedicationDateFilter filter) =>
    switch (filter) {
      MedicationDateFilter.today => context.l10n.historyFilterToday,
      MedicationDateFilter.week => context.l10n.historyFilterWeek,
      MedicationDateFilter.month => context.l10n.historyFilterMonth,
      MedicationDateFilter.year => context.l10n.historyFilterYear,
      MedicationDateFilter.all => context.l10n.historyFilterAll,
    };

String _reminderFilterLabel(
  BuildContext context,
  MedicationReminderFilter filter,
) => switch (filter) {
  MedicationReminderFilter.all => context.l10n.historyFilterAll,
  MedicationReminderFilter.withReminder =>
    context.l10n.medicationsFilterReminderWith,
  MedicationReminderFilter.withoutReminder =>
    context.l10n.medicationsFilterReminderWithout,
};

String _usageFilterLabel(BuildContext context, MedicationUsageFilter filter) =>
    switch (filter) {
      MedicationUsageFilter.all => context.l10n.historyFilterAll,
      MedicationUsageFilter.everUsed =>
        context.l10n.medicationsFilterUsageEverUsed,
      MedicationUsageFilter.neverUsed =>
        context.l10n.medicationsFilterUsageNeverUsed,
    };

/// Confirms a just-saved reminder, spelling out when it will next fire. The
/// "tomorrow" case matters most: a time already past today rolls to the next
/// day (see [LocalNotificationScheduler]), which otherwise reads as "nothing
/// happened". Mirrors that scheduler's boundary (a time == now counts as past).
void _showReminderScheduledSnack(BuildContext context, int minuteOfDay) {
  final l10n = context.l10n;
  final now = DateTime.now();
  final todayAt = DateTime(
    now.year,
    now.month,
    now.day,
    minuteOfDay ~/ 60,
    minuteOfDay % 60,
  );
  final firesTomorrow = !todayAt.isAfter(now);
  final time =
      '${(minuteOfDay ~/ 60).toString().padLeft(2, '0')}:'
      '${(minuteOfDay % 60).toString().padLeft(2, '0')}';
  final message = firesTomorrow
      ? l10n.remindersScheduledTomorrow(time)
      : l10n.remindersScheduledToday(time);
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

/// Manages saved medications: add, rename, delete, filter by when they were
/// added / whether they have a reminder / whether they've ever been used —
/// and each medication's daily reminders live right on its own card. The
/// 3-tap log flow's own medication picker (`MedicationStep`) is untouched
/// and unaffected by anything filtered or sorted here.
class MedicationsScreen extends ConsumerStatefulWidget {
  const MedicationsScreen({super.key});

  @override
  ConsumerState<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends ConsumerState<MedicationsScreen> {
  bool _handlingAdd = false;

  final ScrollController _scrollController = ScrollController();

  /// One key per medication card, so the highlight flow can scroll a card
  /// into view via [Scrollable.ensureVisible].
  final Map<String, GlobalKey> _cardKeys = {};

  /// The card currently flashing its highlight (from the dashboard's
  /// next-reminder tap), or null.
  String? _highlightedId;
  Timer? _highlightTimer;
  bool _handlingHighlight = false;

  /// Whether the app bar is showing the name-search field in place of the
  /// title. The query itself lives in [medicationSearchProvider] so filtering
  /// survives a tab switch; this only toggles the field's visibility.
  bool _searching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  /// Rough per-card height, used only to jump a not-yet-built target near the
  /// viewport so its key resolves before the precise ensureVisible.
  static double get _estimatedCardExtent => AppSpacingConstant.h96;

  @override
  void initState() {
    super.initState();
    // The dashboard's add shortcut may have set a request before this tab was
    // ever built — pick it up on first mount. (The highlight request is driven
    // by a watch in build, which also fires when the tab is re-activated.)
    if (ref.read(medicationAddRequestProvider)) _handleAddRequest();
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Reveals the search field and focuses it.
  void _startSearch() {
    setState(() => _searching = true);
    _searchFocus.requestFocus();
  }

  /// Hides the search field and clears the query so the full list returns.
  void _stopSearch() {
    _searchController.clear();
    ref.read(medicationSearchProvider.notifier).clear();
    _searchFocus.unfocus();
    setState(() => _searching = false);
  }

  /// The name-search field shown in the app bar title slot while searching.
  Widget _searchField(BuildContext context) {
    final l10n = context.l10n;
    return TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      textInputAction: TextInputAction.search,
      style: AppTextStyle.titleMedium,
      cursorColor: AppColors.primary,
      onChanged: ref.read(medicationSearchProvider.notifier).setQuery,
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: l10n.medicationsSearchHint,
        hintStyle: AppTextStyle.titleMedium.secondary,
      ),
    );
  }

  /// Consumes a pending "add medication" request and opens the dialog, once,
  /// after the current frame (so it runs post-navigation, never during build).
  void _handleAddRequest() {
    if (_handlingAdd) return;
    _handlingAdd = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(medicationAddRequestProvider.notifier).consume();
      if (mounted) await _add();
      _handlingAdd = false;
    });
  }

  /// Consumes a pending highlight request, flashes the card for a second, and
  /// scrolls it into view. Kicked off from a post-frame callback in [build] so
  /// it runs after navigation settles and the list has a chance to build.
  Future<void> _beginHighlight(String medicationId) async {
    if (!mounted) {
      _handlingHighlight = false;
      return;
    }
    ref.read(medicationHighlightProvider.notifier).consume();
    setState(() => _highlightedId = medicationId);
    await _scrollToCard(medicationId);
    _handlingHighlight = false;
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _highlightedId = null);
    });
  }

  /// Waits (a bounded number of frames) for the target card to build — the
  /// list may still be loading right after navigation — nudging toward its
  /// index so it does, then aligns it into view.
  Future<void> _scrollToCard(String medicationId) async {
    for (var attempt = 0; attempt < 15; attempt++) {
      if (!mounted) return;
      final cardContext = _cardKeys[medicationId]?.currentContext;
      if (cardContext != null && cardContext.mounted) {
        await Scrollable.ensureVisible(
          cardContext,
          alignment: 0.1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      if (_scrollController.hasClients) {
        final meds = ref.read(filteredMedicationsProvider);
        final index = meds.indexWhere((m) => m.id == medicationId);
        if (index >= 0) {
          final offset = (index * _estimatedCardExtent).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          );
          if ((offset - _scrollController.offset).abs() > 1) {
            _scrollController.jumpTo(offset);
          }
        }
      }
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  Future<void> _add() async {
    final name = await showMedicationNameDialog(context);
    if (name == null) return;
    await ref.read(medicationsControllerProvider).add(name);
  }

  @override
  Widget build(BuildContext context) {
    // Handle requests that arrive while this tab is already alive.
    ref.listen(medicationAddRequestProvider, (_, next) {
      if (next) _handleAddRequest();
    });
    // Drive the highlight from a watch (not a listen) so it also fires when the
    // tab is re-activated with a request already pending (an offstage listen
    // stays paused).
    final highlightId = ref.watch(medicationHighlightProvider);
    if (highlightId != null && !_handlingHighlight) {
      _handlingHighlight = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _beginHighlight(highlightId),
      );
    }
    final l10n = context.l10n;
    final medications = ref.watch(filteredMedicationsProvider);
    final filters = ref.watch(medicationFiltersProvider);
    final filtersController = ref.read(medicationFiltersProvider.notifier);
    final searchQuery = ref.watch(medicationSearchProvider);
    // Measured here (the body-building context) and handed to both the filter
    // strip and the list gap so they use the identical value — reading it again
    // deeper in the tree can drift in this nested-Scaffold setup.
    final topInset = AppScaffold.bodyTopInset(context);
    final filterBarHeight = PinnedFilterBar.heightFor(topInset);

    return AppScaffold(
      // While searching, the title slot becomes the search field and a close
      // button takes the leading slot; otherwise the tab title with a search
      // affordance right after it.
      title: _searching ? _searchField(context) : Text(l10n.medicationsTitle),
      leading: _searching
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: l10n.commonCancel,
              onPressed: _stopSearch,
            )
          : null,
      // No FAB here: this is a shell tab, and the floating glass bottom nav
      // overlays tab content (extendBody) — a FAB would sit right under its
      // hit-test region and silently eat the tap. Every other tab puts its
      // primary action in the app bar instead; this one follows suit.
      actions: _searching
          ? [
              if (searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.medicationsSearchClear,
                  onPressed: () {
                    _searchController.clear();
                    ref.read(medicationSearchProvider.notifier).clear();
                    _searchFocus.requestFocus();
                  },
                ),
              SizedBox(width: AppSpacingConstant.w12),
            ]
          : [
              IconButton(
                icon: Icon(Icons.search, color: AppColors.secondary),
                tooltip: l10n.medicationsSearchTooltip,
                onPressed: _startSearch,
              ),
              HorizontalSpacing(),
              IconButton(
                icon: Icon(Icons.add, color: AppColors.secondary),
                tooltip: l10n.logAddMedication,
                onPressed: _add,
              ),
              SizedBox(width: AppSpacingConstant.w12),
            ],
      // No outer top padding: like History, the list scrolls behind the
      // translucent app bar so it fills the screen. The filter row is a fixed
      // PinnedFilterBar floating over the top of the list (in a Stack) — it
      // stays anchored just below the app bar while the cards scroll under it.
      body: Stack(
        children: [
          AppRefreshIndicator(
            // Drop the spinner below the filter strip, not over its chips.
            edgeOffset: filterBarHeight + AppSpacingConstant.h8,
            onRefresh: () => pullRefresh(() {
              ref
                ..invalidate(medicationsStreamProvider)
                ..invalidate(medicationRemindersStreamProvider);
            }),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (medications.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    // Clear the app bar + filter strip so the empty state
                    // centers in the space below them.
                    child: Padding(
                      padding: EdgeInsets.only(top: filterBarHeight),
                      child: EmptyState(
                        icon: Icons.medication_outlined,
                        message: searchQuery.trim().isEmpty
                            ? l10n.medicationsEmpty
                            : l10n.medicationsSearchEmpty,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacingConstant.w16,
                      filterBarHeight,
                      AppSpacingConstant.w16,
                      AppScaffold.bottomNavInset(context) +
                          AppSpacingConstant.h16,
                    ),
                    sliver: SliverList.separated(
                      itemCount: medications.length,
                      separatorBuilder: (_, _) =>
                          SizedBox(height: AppSpacingConstant.h8),
                      itemBuilder: (context, index) {
                        final medication = medications[index];
                        return _MedicationCard(
                          key: _cardKeys.putIfAbsent(
                            medication.id,
                            GlobalKey.new,
                          ),
                          medication: medication,
                          highlighted: medication.id == _highlightedId,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: PinnedFilterBar(
              topInset: topInset,
              child: _filterRow(context, filters, filtersController),
            ),
          ),
        ],
      ),
    );
  }

  /// The row of independent filter chips (date / reminder / usage).
  /// [PinnedFilterBar] supplies the horizontal scrolling, so this returns a
  /// bare [Row] — don't wrap it in a scroll view (that would nest two).
  Widget _filterRow(
    BuildContext context,
    MedicationFilters filters,
    MedicationFiltersController filtersController,
  ) {
    final l10n = context.l10n;
    return Row(
      children: [
        AppFilterChip<MedicationDateFilter>(
          // The row holds 3 independent chips — at their default ("all")
          // they'd otherwise all just read "All" with nothing to tell them
          // apart, so the axis name leads until something is actually picked.
          label: filters.date == MedicationDateFilter.all
              ? l10n.medicationsFilterDateTitle
              : _dateFilterLabel(context, filters.date),
          selected: filters.date,
          options: MedicationDateFilter.values,
          optionLabelBuilder: (value) => _dateFilterLabel(context, value),
          onSelected: filtersController.setDate,
          sheetTitle: l10n.medicationsFilterDateTitle,
        ),
        SizedBox(width: AppSpacingConstant.w8),
        AppFilterChip<MedicationReminderFilter>(
          label: filters.reminder == MedicationReminderFilter.all
              ? l10n.medicationsFilterReminderTitle
              : _reminderFilterLabel(context, filters.reminder),
          selected: filters.reminder,
          options: MedicationReminderFilter.values,
          optionLabelBuilder: (value) => _reminderFilterLabel(context, value),
          onSelected: filtersController.setReminder,
          sheetTitle: l10n.medicationsFilterReminderTitle,
        ),
        SizedBox(width: AppSpacingConstant.w8),
        AppFilterChip<MedicationUsageFilter>(
          label: filters.usage == MedicationUsageFilter.all
              ? l10n.medicationsFilterUsageTitle
              : _usageFilterLabel(context, filters.usage),
          selected: filters.usage,
          options: MedicationUsageFilter.values,
          optionLabelBuilder: (value) => _usageFilterLabel(context, value),
          onSelected: filtersController.setUsage,
          sheetTitle: l10n.medicationsFilterUsageTitle,
        ),
      ],
    );
  }
}

class _MedicationCard extends ConsumerStatefulWidget {
  const _MedicationCard({
    required this.medication,
    this.highlighted = false,
    super.key,
  });

  final Medication medication;

  /// Briefly flashed (a primary border + glow) when the user jumped here from
  /// the dashboard's next-reminder banner.
  final bool highlighted;

  /// Reminders beyond this many start collapsed — a med taken 4+ times a
  /// day is rare, and the "Add reminder" action should stay reachable
  /// without scrolling through every row first.
  static const collapsedLimit = 3;

  @override
  ConsumerState<_MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends ConsumerState<_MedicationCard> {
  bool _expanded = false;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final name = await showMedicationNameDialog(
      context,
      initial: widget.medication.name,
    );
    if (name == null) return;
    await ref
        .read(medicationsControllerProvider)
        .rename(widget.medication, name);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showAppDialog<bool>(
      context,
      builder: (dialogContext) => AppDialog(
        title: l10n.medicationsDeleteTitle,
        content: Text(
          l10n.medicationsDeleteBody,
          style: AppTextStyle.bodyMedium,
        ),
        actions: [
          AppButton.text(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: l10n.commonCancel,
          ),
          AppButton.destructive(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            label: l10n.settingsDeleteConfirmAction,
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(medicationsControllerProvider).delete(widget.medication.id);
  }

  void _openActions(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    showAppBottomSheet<void>(
      context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.medicationsEditAction),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _rename(context, ref);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: scheme.error),
              title: Text(
                l10n.settingsDeleteConfirmAction,
                style: TextStyle(color: scheme.error),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _delete(context, ref);
              },
            ),
            SizedBox(height: AppSpacingConstant.h8),
          ],
        ),
      ),
    );
  }

  Future<void> _addReminder(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    // Default a few minutes ahead so the reminder actually fires soon —
    // defaulting to "now" would land in the past and roll to tomorrow.
    final base = DateTime.now().add(const Duration(minutes: 5));
    final time = await showAppTimePickerSheet(
      context,
      title: l10n.remindersAdd,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
    );
    if (time == null || !context.mounted) return;

    final minuteOfDay = time.hour * 60 + time.minute;
    final ok = await ref
        .read(remindersControllerProvider)
        .add(
          medicationId: widget.medication.id,
          medicationName: widget.medication.name,
          minuteOfDay: minuteOfDay,
          notificationTitle: l10n.reminderNotificationTitle,
          notificationBody: l10n.reminderNotificationBody('{name}'),
        );
    if (!context.mounted) return;
    if (ok) {
      _showReminderScheduledSnack(context, minuteOfDay);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.remindersPermissionDenied)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reminders = ref.watch(
      remindersForMedicationProvider(widget.medication.id),
    );
    final createdAt = widget.medication.createdAt;
    final addedLabel = createdAt == null
        ? l10n.medicationsAddedUnknown
        : l10n.medicationsAddedOn(
            DateFormat.yMMMd(l10n.localeName).format(createdAt.toLocal()),
          );

    final overflowing = reminders.length > _MedicationCard.collapsedLimit;
    final visibleReminders = overflowing && !_expanded
        ? reminders.take(_MedicationCard.collapsedLimit).toList()
        : reminders;

    // Drive the highlight from a single 0..1 value and derive the border +
    // glow from it — building the decoration per-frame keeps the fade
    // monotonic. (AnimatedContainer lerps the whole BoxDecoration, and
    // interpolating boxShadow toward null flickers brighter near the end.)
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: widget.highlighted ? 1 : 0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, t, child) => Container(
        // Glow sits behind the card; the border is painted in the FOREGROUND
        // so it isn't hidden under the card's opaque surface.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacingConstant.r12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35 * t),
              blurRadius: AppSpacingConstant.r16 * t,
            ),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacingConstant.r12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: t),
            width: 2,
          ),
        ),
        child: child,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.medication_outlined),
              title: Text(
                widget.medication.name,
                style: AppTextStyle.titleMedium,
              ),
              subtitle: Text(
                addedLabel,
                style: AppTextStyle.bodySmall.secondary,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _openActions(context, ref),
              ),
            ),
            for (final view in visibleReminders) _ReminderRow(view: view),
            if (overflowing)
              _ExpandRemindersToggle(
                expanded: _expanded,
                hiddenCount: reminders.length - _MedicationCard.collapsedLimit,
                onTap: () => setState(() => _expanded = !_expanded),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacingConstant.w16,
                0,
                AppSpacingConstant.w16,
                AppSpacingConstant.h12,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppButton.text(
                  onPressed: () => _addReminder(context, ref),
                  icon: Icons.add_alarm,
                  label: l10n.remindersAdd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Show N more" / "Show less" row under a card's reminder list once it's
/// past [_MedicationCard.collapsedLimit].
class _ExpandRemindersToggle extends StatelessWidget {
  const _ExpandRemindersToggle({
    required this.expanded,
    required this.hiddenCount,
    required this.onTap,
  });

  final bool expanded;
  final int hiddenCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      dense: true,
      leading: Icon(
        expanded ? Icons.expand_less : Icons.expand_more,
        color: AppColors.primary,
      ),
      title: Text(
        expanded
            ? l10n.medicationsShowFewerReminders
            : l10n.medicationsShowMoreReminders(hiddenCount),
        style: AppTextStyle.labelLarge.copyWith(color: AppColors.primary),
      ),
      onTap: onTap,
    );
  }
}

class _ReminderRow extends ConsumerWidget {
  const _ReminderRow({required this.view});

  final MedicationReminderView view;

  /// Opens the wheel picker pre-filled with this reminder's time; on confirm,
  /// updates the time and reschedules the notification.
  Future<void> _editTime(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final reminder = view.reminder;
    final picked = await showAppTimePickerSheet(
      context,
      title: l10n.remindersEditTitle,
      initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
    );
    if (picked == null || !context.mounted) return;
    final minuteOfDay = picked.hour * 60 + picked.minute;
    await ref
        .read(remindersControllerProvider)
        .updateTime(
          reminder,
          medicationName: view.medicationName,
          minuteOfDay: minuteOfDay,
          notificationTitle: l10n.reminderNotificationTitle,
          notificationBody: l10n.reminderNotificationBody('{name}'),
        );
    // Only a scheduled (enabled) reminder actually fires — don't promise a
    // time for a disabled one.
    if (context.mounted && reminder.enabled) {
      _showReminderScheduledSnack(context, minuteOfDay);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reminder = view.reminder;
    // Zero-padded 24h, matching the wheel picker it was set with
    // (AppTimePickerSheet) rather than TimeOfDay.format's locale-dependent
    // 12h/AM-PM — picking and reading a time should never disagree on
    // format.
    final time =
        '${reminder.hour.toString().padLeft(2, '0')}:'
        '${reminder.minute.toString().padLeft(2, '0')}';

    return ListTile(
      dense: true,
      // Tap the row to change the time (the switch/delete keep their own taps).
      onTap: () => _editTime(context, ref),
      leading: const Icon(Icons.alarm),
      title: Text(time),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: reminder.enabled,
            onChanged: (enabled) => ref
                .read(remindersControllerProvider)
                .setEnabled(
                  reminder,
                  medicationName: view.medicationName,
                  notificationTitle: l10n.reminderNotificationTitle,
                  notificationBody: l10n.reminderNotificationBody('{name}'),
                  enabled: enabled,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () =>
                ref.read(remindersControllerProvider).delete(reminder.id),
          ),
        ],
      ),
    );
  }
}
