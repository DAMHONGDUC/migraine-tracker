part of 'medication_detail_screen.dart';

/// What the box says, for the fields the user filled in. Absent rows are
/// absent, not "—": an empty label reads as missing data the app lost, and
/// none of this was ever required.
class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.medication});

  final Medication medication;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          _DetailRow(
            label: l10n.medicationFormDescription,
            value: medication.description,
          ),
          _DetailRow(
            label: l10n.medicationFormIngredients,
            value: medication.ingredients,
          ),
          _DetailRow(
            label: l10n.medicationFormStrength,
            value: medication.strength,
          ),
          _DetailRow(
            label: l10n.medicationFormDosage,
            value: medication.dosage,
          ),
          _DetailRow(
            label: l10n.medicationFormInstructions,
            value: medication.instructions,
          ),
        ],
      ),
    );
  }
}

/// One field: its label over what the user wrote. Renders nothing at all
/// when the field was left blank.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();

    return ListTile(
      title: Text(label, style: AppTextStyle.bodyMedium.secondary),
      subtitle: Text(value!, style: AppTextStyle.bodyLarge),
    );
  }
}
