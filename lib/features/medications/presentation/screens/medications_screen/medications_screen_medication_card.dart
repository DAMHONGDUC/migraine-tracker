part of 'medications_screen.dart';

/// One medication in the list: name, when it was added, and how many
/// reminders it has. The reminders themselves are a tap away — the whole card
/// opens [MedicationDetailScreen].
class _MedicationCard extends ConsumerWidget {
  const _MedicationCard({required this.medication, super.key});

  final Medication medication;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final int reminderCount = ref
        .watch(remindersForMedicationProvider(medication.id))
        .length;
    final DateTime? createdAt = medication.createdAt;
    final String addedLabel = createdAt == null
        ? l10n.medicationsAddedUnknown
        : l10n.medicationsAddedOn(
            DateFormat.yMMMd(l10n.localeName).format(createdAt.toLocal()),
          );

    return SdCardV2(
      child: ListTile(
        onTap: () => context.pushNamed(
          AppRoutes.medication.name,
          pathParameters: <String, String>{
            AppRoutes.medicationIdParam: medication.id,
          },
        ),
        leading: const SdIconV2(icon: Icons.medication_outlined),
        title: Text(medication.name, style: AppTextStyle.titleMedium),
        subtitle: Text(
          '$addedLabel · ${l10n.medicationsReminderCount(reminderCount)}',
          style: AppTextStyle.bodySmall.secondary,
        ),
        trailing: SdIconV2(
          icon: Icons.chevron_right,
          size: SdSpacingConstant.r20,
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
