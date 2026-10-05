import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/premium_limit_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/extensions/medication_effectiveness_label.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/router/navigation_utils.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icon_constant.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/widgets/active_filter_summary.dart';
import '../../../../../core/widgets/all_filters_pill.dart';
import '../../../../../core/widgets/all_filters_sheet.dart';
import '../../../../../core/widgets/free_limit_progress.dart';
import '../../../../../core/widgets/medication_name_dialog.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../insights/domain/entities/medication_effectiveness_result.dart';
import '../../../../insights/domain/entities/medication_overuse_result.dart';
import '../../../../insights/providers.dart';
import '../../../domain/entities/medication.dart';
import '../../../domain/enums/medication_filters.dart';
import '../../../providers.dart';
import '../../controllers/medication_filters_controller.dart';
import '../../widgets/medication_overuse_banner.dart';

part 'medications_screen_filter_sheet.dart';
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

/// Manages saved medications: add, filter by when they were added / whether they have a reminder / whether they've ever been used, and open one.
class MedicationsScreen extends ConsumerStatefulWidget {
  const MedicationsScreen({super.key});

  @override
  ConsumerState<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends ConsumerState<MedicationsScreen> {
  bool _handlingAdd = false;

  /// Whether the app bar is showing the name-search field in place of the title.
  bool _searching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Dashboard's add shortcut may have set a request before this tab was built — pick it up on first mount.
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

  /// The name-search field shown in the app bar title slot while searching. The app's one field, unlabelled — the bar it sits in is the label.
  Widget _searchField(BuildContext context) {
    return SdTextFieldV2(
      controller: _searchController,
      focusNode: _searchFocus,
      hint: context.l10n.medicationsSearchHint,
      textInputAction: TextInputAction.search,
      onChanged: ref.read(medicationSearchProvider.notifier).setQuery,
    );
  }

  /// Consumes a pending "add medication" request and opens the dialog, once, after the current frame (so it runs post-navigation, never during build).
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
    // The limit is named before the pitch — this button says "Add medication", so a purchase screen out of it reads as a bug.
    if (!ref.read(canAddMedicationProvider)) {
      await NavigationUtils.toPaywallFromLimit(
        context,
        ref,
        title: context.l10n.medicationLimitTitle(
          PremiumLimitConstant.medications,
        ),
        body: context.l10n.medicationLimitBody(
          PremiumLimitConstant.medications,
        ),
      );
      return;
    }

    final String? name = await const MedicationNameDialog().show(context);

    if (name == null) return;
    await ref.read(medicationsControllerProvider).add(name);
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
    // Gap cards leave for the bar/filter strip; fixed regardless of collapse state, so the list never jumps mid-scroll (see SdCollapsingFilterScaffoldV2).
    final filterBarHeight = SdContentPaddingV2.belowPinnedFilterBar(context);
    // Null while premium. When shown it takes the filter strip's gap, so whatever follows starts flush against it instead of clearing the bar twice.
    final int? used = ref.watch(medicationsUsedProvider);
    // A safety count outranks a plan meter, so it takes the top slot.
    final bool overusing =
        ref.watch(medicationOveruseProvider).risk != MedicationOveruseRisk.none;
    final int activeFilters = filters.activeCount;
    final double limitTop = overusing ? 0 : filterBarHeight;
    // The summary takes the strip's gap only when nothing above it already has.
    final double summaryTop = overusing || used != null ? 0 : filterBarHeight;
    final double contentTop = overusing || used != null || activeFilters > 0
        ? 0
        : filterBarHeight;

    return SdCollapsingFilterScaffoldV2(
      // - While searching: title slot is the search field, close button leads. - Otherwise: tab title with a search affordance right after it.
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
      // - No FAB: the floating glass nav overlays content and would eat the tap. - Every other tab puts its primary action in the app bar; this follows suit.
      actions: _searching
          ? [
              if (searchQuery.isNotEmpty)
                SdAppBarButtonV2(
                  icon: AppIconConstant.close,
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
              SdAppBarButtonV2(
                icon: AppIconConstant.search,
                color: AppColors.secondary,
                tooltip: l10n.medicationsSearchTooltip,
                onPressed: _startSearch,
              ),
              SdHorizontalSpacingV2(),
              SdAppBarButtonV2(
                icon: AppIconConstant.add,
                color: AppColors.secondary,
                tooltip: l10n.logAddMedication,
                onPressed: _add,
              ),
              SizedBox(width: SdSpacingConstant.w12),
            ],
      filter: _filterRow(context, filters, filtersController),
      // Pinned under the app bar, never lifted into it (owner's call): the strip is where the filters are, and a bar that takes them over moves them mid-scroll.
      collapsible: false,
      // No outer top padding: list scrolls behind the translucent app bar, like History.
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
            if (overusing)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  SdContentPaddingV2.horizontal,
                  filterBarHeight,
                  SdContentPaddingV2.horizontal,
                  SdContentPaddingV2.listItemGap,
                ),
                sliver: const SliverToBoxAdapter(
                  child: MedicationOveruseBanner(),
                ),
              ),
            // Ahead of the first card, and ahead of the empty state too — how many the free plan holds is worth saying before any exist.
            if (used != null)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  SdContentPaddingV2.horizontal,
                  limitTop,
                  SdContentPaddingV2.horizontal,
                  SdContentPaddingV2.listItemGap,
                ),
                sliver: SliverToBoxAdapter(
                  child: FreeLimitProgress(
                    used: used,
                    limit: PremiumLimitConstant.medications,
                    titleBuilder: (int left) => l10n.freeLimitMedications(left),
                  ),
                ),
              ),
            // Under the meter, above the first card: how much of the list is being hidden, and the one tap that gives it back.
            if (activeFilters > 0)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  SdContentPaddingV2.horizontal,
                  summaryTop,
                  SdContentPaddingV2.horizontal,
                  SdContentPaddingV2.listItemGap,
                ),
                sliver: SliverToBoxAdapter(
                  child: ActiveFilterSummary(
                    count: activeFilters,
                    onClear: filtersController.reset,
                  ),
                ),
              ),
            if (medications.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                // Clears the app bar + filter strip so the empty state centers below them.
                child: Padding(
                  padding: EdgeInsets.only(top: contentTop),
                  child: SdEmptyStateV2(
                    icon: AppIconConstant.medication,
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
                  contentTop,
                  SdContentPaddingV2.horizontal,
                  SdContentPaddingV2.bottom(context, floatingNav: true),
                ),
                sliver: SliverList.separated(
                  itemCount: medications.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(height: SdContentPaddingV2.listItemGap),
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

  /// Opens every axis in one sheet, and applies what comes back.
  Future<void> _openAllFilters(MedicationFilters filters) async {
    final MedicationFilters? picked = await _MedicationFilterSheet(
      initial: filters,
    ).show(context);

    if (!mounted) return;
    if (picked != null && picked != ref.read(medicationFiltersProvider)) {
      ref.read(medicationFiltersProvider.notifier).apply(picked);
    }
  }

  /// The all-filters pill, then the row of independent filter chips (date / reminder / usage).
  Widget _filterRow(
    BuildContext context,
    MedicationFilters filters,
    MedicationFiltersController filtersController,
  ) {
    final l10n = context.l10n;
    return Row(
      children: [
        AllFiltersPill(
          count: filters.activeCount,
          onTap: () => _openAllFilters(filters),
        ),
        SizedBox(width: SdSpacingConstant.w8),
        SdFilterChipV2<MedicationDateFilter>(
          // 3 chips default to "all" and would all just read "All"; axis name leads until something is actually picked.
          label: filters.date == MedicationDateFilter.all
              ? l10n.medicationsFilterDateTitle
              : _FilterLabels.date(context, filters.date),
          selected: filters.date,
          options: MedicationDateFilter.values,
          optionLabelBuilder: (value) => _FilterLabels.date(context, value),
          onSelected: filtersController.setDate,
          sheetTitle: l10n.medicationsFilterDateTitle,
          // Highlighted while it is narrowing the list, so a filter left on is visible without reading every chip's label.
          active: filters.date != MedicationDateFilter.all,
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
          active: filters.reminder != MedicationReminderFilter.all,
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
          active: filters.usage != MedicationUsageFilter.all,
        ),
      ],
    );
  }
}
