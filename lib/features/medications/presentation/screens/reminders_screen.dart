import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/app_spacing_constant.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_reminder_repository.dart';
import '../../providers.dart';
import '../controllers/reminders_controller.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final medications = await ref.read(medicationRepositoryProvider).getAll();
    if (!context.mounted) return;
    if (medications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.remindersNoMedications)),
      );
      return;
    }

    final medication = medications.length == 1
        ? medications.single
        : await showAppDialog<Medication>(
            context,
            builder: (dialogContext) => AppDialog(
              title: l10n.remindersPickMedication,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final med in medications)
                    AppDialogOption(
                      icon: Icons.medication_outlined,
                      label: med.name,
                      onTap: () => Navigator.of(dialogContext).pop(med),
                    ),
                ],
              ),
            ),
          );
    if (medication == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;

    final ok = await ref
        .read(remindersControllerProvider)
        .add(
          medicationId: medication.id,
          medicationName: medication.name,
          minuteOfDay: time.hour * 60 + time.minute,
          notificationTitle: l10n.reminderNotificationTitle,
          notificationBody: l10n.reminderNotificationBody('{name}'),
        );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.remindersPermissionDenied)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reminders = ref.watch(medicationRemindersStreamProvider);

    return AppScaffold(
      title: Text(l10n.remindersTitle),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add_alarm),
        label: Text(l10n.remindersAdd),
      ),
      body: switch (reminders) {
        AsyncData(value: final list) when list.isEmpty => EmptyState(
          icon: Icons.alarm_outlined,
          message: l10n.remindersEmpty,
        ),
        AsyncData(value: final list) => ListView.separated(
          padding: EdgeInsets.fromLTRB(
            AppSpacingConstant.w16,
            AppScaffold.bodyTopInset(context) + AppSpacingConstant.h16,
            AppSpacingConstant.w16,
            AppSpacingConstant.w16,
          ),
          itemCount: list.length,
          separatorBuilder: (_, _) => SizedBox(height: AppSpacingConstant.h8),
          itemBuilder: (context, index) =>
              _ReminderTile(view: list[index]),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ReminderTile extends ConsumerWidget {
  const _ReminderTile({required this.view});

  final MedicationReminderView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final r = view.reminder;
    final time = TimeOfDay(hour: r.hour, minute: r.minute).format(context);

    return Card(
      child: ListTile(
        leading: const Icon(Icons.alarm),
        title: Text(time, style: context.textTheme.titleMedium),
        subtitle: Text(view.medicationName),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: r.enabled,
              onChanged: (enabled) => ref
                  .read(remindersControllerProvider)
                  .setEnabled(
                    r,
                    medicationName: view.medicationName,
                    notificationTitle: l10n.reminderNotificationTitle,
                    notificationBody: l10n.reminderNotificationBody('{name}'),
                    enabled: enabled,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  ref.read(remindersControllerProvider).delete(r.id),
            ),
          ],
        ),
      ),
    );
  }
}
