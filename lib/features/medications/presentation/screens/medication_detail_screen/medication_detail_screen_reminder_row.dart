part of 'medication_detail_screen.dart';

/// One daily reminder: its time, whether it is armed, and a way to remove it.
class _ReminderRow extends ConsumerWidget {
  const _ReminderRow({required this.view});

  final MedicationReminderView view;

  /// Opens the wheel picker pre-filled with this reminder's time; on confirm, updates the time and reschedules the notification.
  Future<void> _editTime(BuildContext context, WidgetRef ref) async {
    // Ask up front; if permanently off, AppPermission shows the Settings sheet.
    final bool granted = await ref
        .read(appPermissionProvider)
        .ensure(context, AppPermissionType.notification);

    if (!granted || !context.mounted) return;

    final AppLocalizations l10n = context.l10n;
    final MedicationReminder reminder = view.reminder;
    final TimeOfDay? picked = await AppTimePickerSheet(
      title: l10n.remindersEditTitle,
      initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
      isEditMode: true,
    ).show(context);

    if (picked == null || !context.mounted) return;

    final int minuteOfDay = picked.hour * 60 + picked.minute;

    await ref
        .read(remindersControllerProvider)
        .updateTime(
          reminder,
          medicationName: view.medicationName,
          minuteOfDay: minuteOfDay,
          notificationTitle: l10n.reminderNotificationTitle,
          notificationBody: l10n.reminderNotificationBody('{name}'),
        );
    // Only a scheduled (enabled) reminder fires — don't promise a disabled one's time.
    if (context.mounted && reminder.enabled) {
      _ReminderSnack.show(context, minuteOfDay);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final MedicationReminder reminder = view.reminder;
    final String time = DateTimeUtils.hhmm(reminder.hour, reminder.minute);

    return ListTile(
      // Tap the row to change the time (the switch/delete keep their own taps).
      onTap: () => _editTime(context, ref),
      leading: SdIconV2(icon: AppIconConstant.reminder, size: AppIconSize.row),
      title: Text(time, style: AppTextStyle.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SdSwitcherV2(
            size: 0.7,
            value: reminder.enabled,
            onChanged: (bool enabled) => ref
                .read(remindersControllerProvider)
                .setEnabled(
                  reminder,
                  medicationName: view.medicationName,
                  notificationTitle: l10n.reminderNotificationTitle,
                  notificationBody: l10n.reminderNotificationBody('{name}'),
                  enabled: enabled,
                ),
          ),
          SdIconButtonV2(
            icon: SdIconV2(icon: AppIconConstant.delete, size: AppIconSize.row),
            onPressed: () =>
                ref.read(remindersControllerProvider).delete(reminder.id),
          ),
        ],
      ),
    );
  }
}
