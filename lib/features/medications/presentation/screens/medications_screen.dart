import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

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
import '../../domain/entities/medication.dart';
import '../../domain/enums/medication_filters.dart';
import '../../domain/repositories/medication_reminder_repository.dart';
import '../../providers.dart';
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

  @override
  void initState() {
    super.initState();
    // The dashboard's "Add medication" shortcut may have set the request
    // before this tab was ever built — pick it up on first mount.
    if (ref.read(medicationAddRequestProvider)) _handleAddRequest();
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
    final l10n = context.l10n;
    final medications = ref.watch(filteredMedicationsProvider);
    final filters = ref.watch(medicationFiltersProvider);
    final filtersController = ref.read(medicationFiltersProvider.notifier);

    return AppScaffold(
      title: Text(l10n.medicationsTitle),
      // No FAB here: this is a shell tab, and the floating glass bottom nav
      // overlays tab content (extendBody) — a FAB would sit right under its
      // hit-test region and silently eat the tap. Every other tab puts its
      // primary action in the app bar instead; this one follows suit.
      actions: [
        IconButton(
          icon: Icon(Icons.add, color: AppColors.secondary),
          tooltip: l10n.logAddMedication,
          onPressed: _add,
        ),
        SizedBox(width: AppSpacingConstant.w12),
      ],
      body: Padding(
        padding: EdgeInsets.only(
          top: AppScaffold.bodyTopInset(context),
          bottom: AppScaffold.bottomNavInset(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacingConstant.w16,
                vertical: AppSpacingConstant.h12,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    AppFilterChip<MedicationDateFilter>(
                      // The row holds 3 independent chips — at their default
                      // ("all") they'd otherwise all just read "All" with
                      // nothing to tell them apart, so the axis name leads
                      // until something is actually picked.
                      label: filters.date == MedicationDateFilter.all
                          ? l10n.medicationsFilterDateTitle
                          : _dateFilterLabel(context, filters.date),
                      selected: filters.date,
                      options: MedicationDateFilter.values,
                      optionLabelBuilder: (value) =>
                          _dateFilterLabel(context, value),
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
                      optionLabelBuilder: (value) =>
                          _reminderFilterLabel(context, value),
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
                      optionLabelBuilder: (value) =>
                          _usageFilterLabel(context, value),
                      onSelected: filtersController.setUsage,
                      sheetTitle: l10n.medicationsFilterUsageTitle,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: AppRefreshIndicator(
                edgeOffset: 0,
                onRefresh: () => pullRefresh(() {
                  ref
                    ..invalidate(medicationsStreamProvider)
                    ..invalidate(medicationRemindersStreamProvider);
                }),
                child: medications.isEmpty
                    ? ScrollFill(
                        child: EmptyState(
                          icon: Icons.medication_outlined,
                          message: l10n.medicationsEmpty,
                        ),
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          AppSpacingConstant.w16,
                          0,
                          AppSpacingConstant.w16,
                          AppSpacingConstant.w16,
                        ),
                        itemCount: medications.length,
                        separatorBuilder: (_, _) =>
                            SizedBox(height: AppSpacingConstant.h8),
                        itemBuilder: (context, index) =>
                            _MedicationCard(medication: medications[index]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationCard extends ConsumerStatefulWidget {
  const _MedicationCard({required this.medication});

  final Medication medication;

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
    final time = await showAppTimePickerSheet(
      context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null || !context.mounted) return;

    final ok = await ref
        .read(remindersControllerProvider)
        .add(
          medicationId: widget.medication.id,
          medicationName: widget.medication.name,
          minuteOfDay: time.hour * 60 + time.minute,
          notificationTitle: l10n.reminderNotificationTitle,
          notificationBody: l10n.reminderNotificationBody('{name}'),
        );
    if (!ok && context.mounted) {
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

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.medication_outlined),
            title: Text(
              widget.medication.name,
              style: AppTextStyle.titleMedium,
            ),
            subtitle: Text(addedLabel, style: AppTextStyle.bodySmall.secondary),
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
