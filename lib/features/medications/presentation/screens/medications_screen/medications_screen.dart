import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';
import 'package:migraine_tracker/core/permissions/app_permission.dart';
import 'package:migraine_tracker/core/widgets/spacing/horizontal_spacing.dart';

import '../../../../../core/constants/app_content_padding.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/app_bar_button.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_dialog.dart';
import '../../../../../core/widgets/app_filter_sheet.dart';
import '../../../../../core/widgets/app_icon.dart';
import '../../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../../core/widgets/app_snack_bar.dart';
import '../../../../../core/widgets/app_time_picker_sheet.dart';
import '../../../../../core/widgets/collapsing_filter_scaffold.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/medication_name_dialog.dart';
import '../../../domain/entities/medication.dart';
import '../../../domain/enums/medication_filters.dart';
import '../../../domain/repositories/medication_reminder_repository.dart';
import '../../../providers.dart';
import '../../controllers/medication_filters_controller.dart';

part 'medications_screen_expand_reminders_toggle.dart';
part 'medications_screen_medication_card.dart';
part 'medications_screen_reminder_row.dart';

/// Localized labels for the medications tab's three filter axes.
final class _FilterLabels {
  static String date(BuildContext context, MedicationDateFilter filter) =>
      switch (filter) {
        MedicationDateFilter.today => context.l10n.historyFilterToday,
        MedicationDateFilter.week => context.l10n.historyFilterWeek,
        MedicationDateFilter.month => context.l10n.historyFilterMonth,
        MedicationDateFilter.year => context.l10n.historyFilterYear,
        MedicationDateFilter.all => context.l10n.historyFilterAll,
      };

  static String reminder(
    BuildContext context,
    MedicationReminderFilter filter,
  ) => switch (filter) {
    MedicationReminderFilter.all => context.l10n.historyFilterAll,
    MedicationReminderFilter.withReminder =>
      context.l10n.medicationsFilterReminderWith,
    MedicationReminderFilter.withoutReminder =>
      context.l10n.medicationsFilterReminderWithout,
  };

  static String usage(BuildContext context, MedicationUsageFilter filter) =>
      switch (filter) {
        MedicationUsageFilter.all => context.l10n.historyFilterAll,
        MedicationUsageFilter.everUsed =>
          context.l10n.medicationsFilterUsageEverUsed,
        MedicationUsageFilter.neverUsed =>
          context.l10n.medicationsFilterUsageNeverUsed,
      };
}

/// Confirms a just-saved reminder, spelling out when it will next fire.
final class _ReminderSnack {
  /// The "tomorrow" case matters most: a time already past today rolls to the
  /// next day (see [LocalNotificationScheduler]), which otherwise reads as
  /// "nothing happened". Mirrors that scheduler's boundary (a time == now
  /// counts as past).
  static void show(BuildContext context, int minuteOfDay) {
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
    AppSnackBarUtils.success(context, message);
  }
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
    for (int attempt = 0; attempt < 15; attempt++) {
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
    final name = await const MedicationNameDialog().show(context);
    if (name == null) return;
    await ref.read(medicationsControllerProvider).add(name);
  }

  /// Debug-only: fires a test notification ~10s out and confirms via snackbar.
  Future<void> _sendTestNotification() async {
    final l10n = context.l10n;
    final granted = await ref
        .read(appPermissionProvider)
        .ensure(context, AppPermissionType.notification);
    if (!granted || !mounted) return;
    await ref
        .read(remindersControllerProvider)
        .sendTest(title: l10n.remindersTestTitle, body: l10n.remindersTestBody);
    if (!mounted) return;
    AppSnackBarUtils.info(context, l10n.remindersTestScheduled);
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
    // The gap the cards leave for the app bar and the filter strip above them.
    // Fixed whether the strip is showing or lifted into the bar, so the list
    // never jumps mid-scroll (see CollapsingFilterScaffold).
    final filterBarHeight = AppContentPadding.belowPinnedFilterBar(context);

    return CollapsingFilterScaffold(
      // While searching, the title slot becomes the search field and a close
      // button takes the leading slot; otherwise the tab title with a search
      // affordance right after it.
      title: _searching
          ? _searchField(context)
          : Text(l10n.medicationsTitle, style: AppTextStyle.titleLarge),
      leading: _searching
          ? AppBarButton(
              icon: AppBarButton.backIcon,
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
                AppBarButton(
                  icon: Icons.close,
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
              // Debug-only smoke test for notification delivery (kDebugMode
              // strips it from release builds entirely).
              if (kDebugMode) ...[
                AppBarButton(
                  icon: Icons.notification_add_outlined,
                  color: AppColors.secondary,
                  tooltip: l10n.remindersTestTooltip,
                  onPressed: _sendTestNotification,
                ),
                HorizontalSpacing(),
              ],

              AppBarButton(
                icon: Icons.search,
                color: AppColors.secondary,
                tooltip: l10n.medicationsSearchTooltip,
                onPressed: _startSearch,
              ),
              HorizontalSpacing(),
              AppBarButton(
                icon: Icons.add,
                color: AppColors.secondary,
                tooltip: l10n.logAddMedication,
                onPressed: _add,
              ),
              SizedBox(width: AppSpacingConstant.w12),
            ],
      // The filter chips sit under the app bar while reading and lift into it
      // once the list scrolls — except while searching, when the bar is the
      // search field's and must stay put.
      filter: _filterRow(context, filters, filtersController),
      collapsible: !_searching,
      // No outer top padding: like History, the list scrolls behind the
      // translucent app bar so it fills the screen.
      body: AppRefreshIndicator(
        // Drop the spinner below the filter strip, not over its chips.
        edgeOffset: filterBarHeight + AppSpacingConstant.h8,
        onRefresh: () => AppRefreshIndicator.run(() {
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
                  AppContentPadding.horizontal,
                  filterBarHeight,
                  AppContentPadding.horizontal,
                  AppContentPadding.bottom(context, floatingNav: true),
                ),
                sliver: SliverList.separated(
                  itemCount: medications.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(height: AppSpacingConstant.h8),
                  itemBuilder: (context, index) {
                    final medication = medications[index];
                    return _MedicationCard(
                      key: _cardKeys.putIfAbsent(medication.id, GlobalKey.new),
                      medication: medication,
                      highlighted: medication.id == _highlightedId,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The row of independent filter chips (date / reminder / usage).
  /// `CollapsingFilterScaffold` supplies the horizontal scrolling in both places
  /// it shows this row, so it stays a bare [Row] — a scroll view here would
  /// nest two.
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
              : _FilterLabels.date(context, filters.date),
          selected: filters.date,
          options: MedicationDateFilter.values,
          optionLabelBuilder: (value) => _FilterLabels.date(context, value),
          onSelected: filtersController.setDate,
          sheetTitle: l10n.medicationsFilterDateTitle,
        ),
        SizedBox(width: AppSpacingConstant.w8),
        AppFilterChip<MedicationReminderFilter>(
          label: filters.reminder == MedicationReminderFilter.all
              ? l10n.medicationsFilterReminderTitle
              : _FilterLabels.reminder(context, filters.reminder),
          selected: filters.reminder,
          options: MedicationReminderFilter.values,
          optionLabelBuilder: (value) => _FilterLabels.reminder(context, value),
          onSelected: filtersController.setReminder,
          sheetTitle: l10n.medicationsFilterReminderTitle,
        ),
        SizedBox(width: AppSpacingConstant.w8),
        AppFilterChip<MedicationUsageFilter>(
          label: filters.usage == MedicationUsageFilter.all
              ? l10n.medicationsFilterUsageTitle
              : _FilterLabels.usage(context, filters.usage),
          selected: filters.usage,
          options: MedicationUsageFilter.values,
          optionLabelBuilder: (value) => _FilterLabels.usage(context, value),
          onSelected: filtersController.setUsage,
          sheetTitle: l10n.medicationsFilterUsageTitle,
        ),
      ],
    );
  }
}
