import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:migraine_tracker/core/permissions/app_permission.dart';
import 'package:system_design/index.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/medication_name_dialog.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/entities/medication.dart';
import '../../../domain/enums/medication_filters.dart';
import '../../../providers.dart';
import '../../controllers/medication_filters_controller.dart';

part 'medications_screen_medication_card.dart';

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

/// Manages saved medications: add, filter by when they were added / whether
/// they have a reminder / whether they've ever been used, and open one. Each
/// row says how many reminders its medication has; reading or changing them
/// happens on [MedicationDetailScreen]. The 3-tap log flow's own medication
/// picker (`MedicationStep`) is untouched and unaffected by anything filtered
/// or sorted here.
class MedicationsScreen extends ConsumerStatefulWidget {
  const MedicationsScreen({super.key});

  @override
  ConsumerState<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends ConsumerState<MedicationsScreen> {
  bool _handlingAdd = false;

  /// Whether the app bar is showing the name-search field in place of the
  /// title. The query itself lives in [medicationSearchProvider] so filtering
  /// survives a tab switch; this only toggles the field's visibility.
  bool _searching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // The dashboard's add shortcut may have set a request before this tab was
    // ever built — pick it up on first mount.
    if (ref.read(medicationAddRequestProvider)) _handleAddRequest();
  }

  @override
  void dispose() {
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

  Future<void> _add() async {
    final String? name = await const MedicationNameDialog().show(context);

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
    SdSnackBarUtilsV2.info(context, l10n.remindersTestScheduled);
  }

  @override
  Widget build(BuildContext context) {
    // Handle requests that arrive while this tab is already alive.
    ref.listen(medicationAddRequestProvider, (_, next) {
      if (next) _handleAddRequest();
    });
    final l10n = context.l10n;
    final medications = ref.watch(filteredMedicationsProvider);
    final filters = ref.watch(medicationFiltersProvider);
    final filtersController = ref.read(medicationFiltersProvider.notifier);
    final searchQuery = ref.watch(medicationSearchProvider);
    // The gap the cards leave for the app bar and the filter strip above them.
    // Fixed whether the strip is showing or lifted into the bar, so the list
    // never jumps mid-scroll (see SdCollapsingFilterScaffoldV2).
    final filterBarHeight = SdContentPaddingV2.belowPinnedFilterBar(context);

    return SdCollapsingFilterScaffoldV2(
      // While searching, the title slot becomes the search field and a close
      // button takes the leading slot; otherwise the tab title with a search
      // affordance right after it.
      title: _searching
          ? _searchField(context)
          : Text(l10n.medicationsTitle, style: AppTextStyle.titleLarge),
      leading: _searching
          ? SdAppBarButtonV2(
              icon: SdAppBarButtonV2.backIcon,
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
                SdAppBarButtonV2(
                  icon: Icons.close,
                  tooltip: l10n.medicationsSearchClear,
                  onPressed: () {
                    _searchController.clear();
                    ref.read(medicationSearchProvider.notifier).clear();
                    _searchFocus.requestFocus();
                  },
                ),
              SizedBox(width: SdSpacingConstant.w12),
            ]
          : [
              // Debug-only smoke test for notification delivery (kDebugMode
              // strips it from release builds entirely).
              if (kDebugMode) ...[
                SdAppBarButtonV2(
                  icon: Icons.notification_add_outlined,
                  color: AppColors.secondary,
                  tooltip: l10n.remindersTestTooltip,
                  onPressed: _sendTestNotification,
                ),
                SdHorizontalSpacingV2(),
              ],

              SdAppBarButtonV2(
                icon: Icons.search,
                color: AppColors.secondary,
                tooltip: l10n.medicationsSearchTooltip,
                onPressed: _startSearch,
              ),
              SdHorizontalSpacingV2(),
              SdAppBarButtonV2(
                icon: Icons.add,
                color: AppColors.secondary,
                tooltip: l10n.logAddMedication,
                onPressed: _add,
              ),
              SizedBox(width: SdSpacingConstant.w12),
            ],
      // The filter chips sit under the app bar while reading and lift into it
      // once the list scrolls — except while searching, when the bar is the
      // search field's and must stay put.
      filter: _filterRow(context, filters, filtersController),
      collapsible: !_searching,
      // No outer top padding: like History, the list scrolls behind the
      // translucent app bar so it fills the screen.
      body: SdRefreshIndicatorV2(
        // Drop the spinner below the filter strip, not over its chips.
        edgeOffset: filterBarHeight + SdSpacingConstant.h8,
        onRefresh: () => SdRefreshIndicatorV2.run(() {
          ref
            ..invalidate(medicationsStreamProvider)
            ..invalidate(medicationRemindersStreamProvider);
        }),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (medications.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                // Clear the app bar + filter strip so the empty state
                // centers in the space below them.
                child: Padding(
                  padding: EdgeInsets.only(top: filterBarHeight),
                  child: SdEmptyStateV2(
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
                  SdContentPaddingV2.horizontal,
                  filterBarHeight,
                  SdContentPaddingV2.horizontal,
                  SdContentPaddingV2.bottom(context, floatingNav: true),
                ),
                sliver: SliverList.separated(
                  itemCount: medications.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(height: SdSpacingConstant.h8),
                  itemBuilder: (context, index) {
                    final Medication medication = medications[index];

                    return _MedicationCard(
                      key: ValueKey<String>(medication.id),
                      medication: medication,
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
  /// `SdCollapsingFilterScaffoldV2` supplies the horizontal scrolling in both places
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
        SdFilterChipV2<MedicationDateFilter>(
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
        SizedBox(width: SdSpacingConstant.w8),
        SdFilterChipV2<MedicationReminderFilter>(
          label: filters.reminder == MedicationReminderFilter.all
              ? l10n.medicationsFilterReminderTitle
              : _FilterLabels.reminder(context, filters.reminder),
          selected: filters.reminder,
          options: MedicationReminderFilter.values,
          optionLabelBuilder: (value) => _FilterLabels.reminder(context, value),
          onSelected: filtersController.setReminder,
          sheetTitle: l10n.medicationsFilterReminderTitle,
        ),
        SizedBox(width: SdSpacingConstant.w8),
        SdFilterChipV2<MedicationUsageFilter>(
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
