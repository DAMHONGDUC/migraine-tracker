part of 'medication_detail_screen.dart';

/// One daily reminder: its time, whether it is armed, and a way to remove it.
class _ReminderRow extends ConsumerWidget {
  const _ReminderRow({required this.view});

  final MedicationReminderView view;

  /// Opens the wheel picker pre-filled with this reminder's time; on confirm,
  /// updates the time and reschedules the notification.
  Future<void> _editTime(BuildContext context, WidgetRef ref) async {
    // A reminder is useless without notification permission — ask up front and,
    // if it's permanently off, AppPermission shows the Settings sheet for us.
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
    // Only a scheduled (enabled) reminder actually fires — don't promise a
    // time for a disabled one.
    if (context.mounted && reminder.enabled) {
      _ReminderSnack.show(context, minuteOfDay);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final MedicationReminder reminder = view.reminder;
    // Zero-padded 24h, matching the wheel picker it was set with
    // (AppTimePickerSheet) rather than TimeOfDay.format's locale-dependent
    // 12h/AM-PM — picking and reading a time should never disagree on
    // format.
    final String time =
        '${reminder.hour.toString().padLeft(2, '0')}:'
        '${reminder.minute.toString().padLeft(2, '0')}';

    return ListTile(
      // Tap the row to change the time (the switch/delete keep their own taps).
      onTap: () => _editTime(context, ref),
      leading: const SdIconV2(icon: Icons.alarm),
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
            icon: const SdIconV2(icon: Icons.delete_outline),
            onPressed: () =>
                ref.read(remindersControllerProvider).delete(reminder.id),
          ),
        ],
      ),
    );
  }
}
