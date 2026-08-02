part of 'attack_detail_screen.dart';

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.attack});

  final Attack attack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEmpty =
        attack.symptoms.isEmpty &&
        attack.triggers.isEmpty &&
        (attack.notes?.isEmpty ?? true);

    void edit() => AttackDetailsSheet(
      attackId: attack.id,
      initialSymptoms: attack.symptoms,
      initialTriggers: attack.triggers,
      initialNotes: attack.notes,
    ).show(context);

    return _Section(
      title: l10n.attackDetailDetailsTitle,
      children: [
        if (isEmpty)
          ListTile(
            title: Text(
              l10n.attackDetailNoDetails,
              style: AppTextStyle.bodyMedium.secondary,
            ),
            trailing: const SdIconV2(icon: Icons.add),
            onTap: edit,
          )
        else ...[
          if (attack.symptoms.isNotEmpty)
            _ReadOnlyRow(
              label: l10n.detailsSymptomsLabel,
              value: attack.symptoms.join(', '),
            ),
          if (attack.triggers.isNotEmpty)
            _ReadOnlyRow(
              label: l10n.detailsTriggersLabel,
              value: attack.triggers.join(', '),
            ),
          if (attack.notes?.isNotEmpty ?? false)
            ListTile(
              title: Text(
                l10n.detailsNotesLabel,
                style: AppTextStyle.bodyLarge,
              ),
              subtitle: Text(
                attack.notes!,
                style: AppTextStyle.bodyMedium.secondary,
              ),
            ),
          Padding(
            padding: EdgeInsets.only(
              right: SdSpacingConstant.w8,
              bottom: SdSpacingConstant.h8,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SdButtonV2(
                variant: SdButtonVariantV2.text,
                onPressed: edit,
                icon: Icons.edit_outlined,
                label: l10n.attackDetailEdit,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Intensity picker: a slider keeps the dialog small (a 10-circle grid
/// belongs to the log flow, not here).
