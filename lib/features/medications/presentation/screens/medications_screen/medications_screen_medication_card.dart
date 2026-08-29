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
    // The one figure that ranks this list against itself. Absent until the
    // medication has an answer, because "no outcomes yet" belongs on the
    // screen that can do something about it, not on every row of a list.
    final MedicationEffectiveness? effectiveness = ref.watch(
      medicationEffectivenessRowProvider(medication.name),
    );

    return SdCardV2(
      child: ListTile(
        onTap: () => context.pushNamed(
          AppRoutes.medication.name,
          pathParameters: <String, String>{
            AppRoutes.medicationIdParam: medication.id,
          },
        ),
        leading: SdIconV2(icon: AppIconConstant.medication,
          size: AppIconSize.row),
        title: Text(medication.name, style: AppTextStyle.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '$addedLabel · ${l10n.medicationsReminderCount(reminderCount)}',
              style: AppTextStyle.bodySmall.secondary,
            ),
            if (effectiveness case final MedicationEffectiveness row
                when row.answeredCount > 0)
              Text(
                row.reliefLabel(l10n),
                style: AppTextStyle.bodySmall.copyWith(
                  color: context.colorScheme.secondary,
                ),
              ),
          ],
        ),
        trailing: SdIconV2(
          icon: AppIconConstant.disclosure,
          size: AppIconSize.affordance,
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
