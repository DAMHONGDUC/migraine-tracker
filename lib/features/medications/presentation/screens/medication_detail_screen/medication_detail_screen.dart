import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:system_design/index.dart';

import '../../../../../core/constants/premium_limit_constant.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/extensions/medication_effectiveness_label.dart';
import '../../../../../core/permissions/app_permission.dart';
import '../../../../../core/router/navigation_utils.dart';
import '../../../../../core/theme/app_icon_constant.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_text_style.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/widgets/app_time_picker_sheet.dart';
import '../../../../../core/widgets/free_limit_progress.dart';
import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../insights/domain/entities/medication_effectiveness_result.dart';
import '../../../../insights/providers.dart';
import '../../../domain/entities/medication.dart';
import '../../../domain/entities/medication_reminder.dart';
import '../../../domain/repositories/medication_reminder_repository.dart';
import '../../../providers.dart';

part 'medication_detail_screen_header.dart';
part 'medication_detail_screen_reminder_row.dart';
part 'medication_detail_screen_effectiveness.dart';
part 'medication_detail_screen_reminder_snack.dart';

/// One medication: when it was added, and every reminder set for it. Reached
/// by tapping its row in the medications tab, or the dashboard's
/// next-reminder banner.
///
/// Reminders live here rather than on the list row — the list says how many
/// there are, this screen is where they are read and changed.
class MedicationDetailScreen extends ConsumerWidget {
  const MedicationDetailScreen({required this.medicationId, super.key});

  final String medicationId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Medication medication,
  ) async {
    final AppLocalizations l10n = context.l10n;
    final bool? confirmed = await showSdDialogV2<bool>(
      context,
      builder: (BuildContext dialogContext) => SdDialogV2(
        title: l10n.medicationsDeleteTitle,
        content: Text(
          l10n.medicationsDeleteBody,
          style: AppTextStyle.bodyMedium,
        ),
        actions: <Widget>[
          SdButtonV2(
            variant: SdButtonVariantV2.text,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: l10n.commonCancel,
          ),
          SdButtonV2(
            variant: SdButtonVariantV2.destructive,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            label: l10n.settingsDeleteConfirmAction,
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(medicationsControllerProvider).delete(medication.id);
    // Nothing left to look at — go back to the list rather than showing "deleted".
    if (context.mounted && context.canPop()) context.pop();
  }

  Future<void> _addReminder(
    BuildContext context,
    WidgetRef ref,
    Medication medication,
  ) async {
    final AppLocalizations l10n = context.l10n;

    // - the limit is named before the pitch: this button says "Add reminder", so a paywall out of nowhere reads as a bug
    // - and both come before the OS prompt, which must never be raised for a reminder that will not be created
    if (!ref.read(canAddReminderProvider)) {
      await NavigationUtils.toPaywallFromLimit(
        context,
        ref,
        title: l10n.reminderLimitTitle(PremiumLimitConstant.reminders),
        body: l10n.reminderLimitBody(PremiumLimitConstant.reminders),
      );
      return;
    }

    // Ask up front; if permanently off, AppPermission shows the Settings sheet.
    final bool granted = await ref
        .read(appPermissionProvider)
        .ensure(context, AppPermissionType.notification);

    if (!granted || !context.mounted) return;

    // Default a few minutes ahead — "now" would land in the past and roll to tomorrow.
    final DateTime base = DateTime.now().add(const Duration(minutes: 5));
    final TimeOfDay? time = await AppTimePickerSheet(
      title: l10n.remindersAdd,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
    ).show(context);

    if (time == null || !context.mounted) return;

    final int minuteOfDay = time.hour * 60 + time.minute;

    await ref
        .read(remindersControllerProvider)
        .add(
          medicationId: medication.id,
          medicationName: medication.name,
          minuteOfDay: minuteOfDay,
          notificationTitle: l10n.reminderNotificationTitle,
          notificationBody: l10n.reminderNotificationBody('{name}'),
        );
    if (!context.mounted) return;
    _ReminderSnack.show(context, minuteOfDay);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final Medication? medication = ref.watch(
      medicationByIdProvider(medicationId),
    );

    // Deleted from under us (or a stale deep link): nothing to show.
    if (medication == null) {
      return SdScaffoldV2(
        title: Text(l10n.medicationsTitle, style: AppTextStyle.titleLarge),
        body: SdEmptyStateV2(
          icon: AppIconConstant.medication,
          message: l10n.medicationDetailMissing,
        ),
      );
    }

    final List<MedicationReminderView> reminders = ref.watch(
      remindersForMedicationProvider(medication.id),
    );
    // Null while premium — there is no limit to draw.
    final int? remindersUsed = ref.watch(remindersUsedProvider);

    return SdScaffoldV2(
      title: Text(medication.name, style: AppTextStyle.titleLarge),
      actions: <Widget>[
        SdAppBarButtonV2(
          icon: AppIconConstant.delete,
          color: context.colorScheme.error,
          tooltip: l10n.settingsDeleteConfirmAction,
          onPressed: () => _delete(context, ref, medication),
        ),
        SizedBox(width: SdSpacingConstant.w12),
      ],
      body: SdActionViewV2(
        // The reminder list grows without bound, and a user with a dozen of
        // them would have to scroll to the end to reach "Add reminder".
        placement: SdActionsPlacementV2.pinned,
        // - Full-bleed: header/"no reminders" text and `SdSectionHeaderV2` pad themselves.
        // - Reminders card takes the gutter as margin instead.
        // - Default `contentPadding` would stack a second one on top (see `account_screen.dart`).
        contentPadding: EdgeInsets.zero,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Header(medication: medication),
            SizedBox(height: SdSpacingConstant.h24),
            SdSectionHeaderV2(
              l10n.medicationDetailEffectiveness,
              first: true,
            ),
            _Effectiveness(medicationName: medication.name),
            SizedBox(height: SdSpacingConstant.h24),
            SdSectionHeaderV2(l10n.medicationDetailReminders),
            // The REMINDER budget, at the top of the section it limits
            // (owner's call); the medication budget used to sit in the footer,
            // saying nothing this screen can act on. Counted across all of them.
            if (remindersUsed != null) ...<Widget>[
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SdContentPaddingV2.horizontal,
                ),
                child: FreeLimitProgress(
                  used: remindersUsed,
                  limit: PremiumLimitConstant.reminders,
                  titleBuilder: (int left) => l10n.freeLimitReminders(left),
                ),
              ),
              SizedBox(height: SdContentPaddingV2.listItemGap),
            ],
            if (reminders.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SdContentPaddingV2.horizontal,
                ),
                child: Text(
                  l10n.medicationDetailNoReminders,
                  style: AppTextStyle.bodyMedium.secondary,
                ),
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SdContentPaddingV2.horizontal,
                ),
                child: SdCardV2(
                  child: Column(
                    children: <Widget>[
                      // Between rows only — a rule above the first or below
                      // the last would draw a line on the card's own edge.
                      for (final (int index, MedicationReminderView view)
                          in reminders.indexed) ...<Widget>[
                        if (index > 0) const SdDividerV2(),
                        _ReminderRow(view: view),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
        actions: <Widget>[
          SdButtonV2(
            variant: SdButtonVariantV2.primary,
            // The button stays — it opens the paywall instead. Only the
            // glyph says the budget is spent, so the label never changes.
            icon: ref.watch(canAddReminderProvider)
                ? AppIconConstant.reminderAdd
                : AppIconConstant.locked,
            onPressed: () => _addReminder(context, ref, medication),
            label: l10n.remindersAdd,
          ),
        ],
      ),
    );
  }
}
