part of 'medications_screen.dart';

class _ReminderRow extends ConsumerWidget {
  const _ReminderRow({required this.view});

  final MedicationReminderView view;

  /// Opens the wheel picker pre-filled with this reminder's time; on confirm,
  /// updates the time and reschedules the notification.
  Future<void> _editTime(BuildContext context, WidgetRef ref) async {
    // A reminder is useless without notification permission — ask up front and,
    // if it's permanently off, AppPermission shows the Settings sheet for us.
    final granted = await ref
        .read(appPermissionProvider)
        .ensure(context, AppPermissionType.notification);
    if (!granted || !context.mounted) return;

    final l10n = context.l10n;
    final reminder = view.reminder;
    final picked = await AppTimePickerSheet(
      title: l10n.remindersEditTitle,
      initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
      isEditMode: true,
    ).show(context);
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
      _ReminderSnack.show(context, minuteOfDay);
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

    final rowPadding = EdgeInsets.symmetric(
      horizontal: AppContentPadding.horizontal,
    ).copyWith(right: AppContentPadding.horizontal / 2);

    return ListTile(
      dense: true,
      // Tap the row to change the time (the switch/delete keep their own taps).
      onTap: () => _editTime(context, ref),
      leading: const AppIcon(icon: Icons.alarm),
      contentPadding: rowPadding,
      title: Text(time, style: AppTextStyle.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSwitcher(
            size: 0.7,
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
          AppIconButton(
            icon: const AppIcon(icon: Icons.delete_outline),
            onPressed: () =>
                ref.read(remindersControllerProvider).delete(reminder.id),
          ),
        ],
      ),
    );
  }
}
