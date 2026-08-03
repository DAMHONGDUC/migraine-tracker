part of 'medication_detail_screen.dart';

/// Name and when it was saved — the two facts the list row also carries, so
/// arriving here from a tap never feels like a different medication.
class _Header extends StatelessWidget {
  const _Header({required this.medication});

  final Medication medication;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final DateTime? createdAt = medication.createdAt;
    final String addedLabel = createdAt == null
        ? l10n.medicationsAddedUnknown
        : l10n.medicationsAddedOn(
            DateFormat.yMMMd(l10n.localeName).format(createdAt.toLocal()),
          );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV2.horizontal),
      child: Row(
        children: <Widget>[
          SdIconV2(
            icon: Icons.medication_outlined,
            size: SdSpacingConstant.r28,
            color: context.colorScheme.primary,
          ),
          SizedBox(width: SdSpacingConstant.w12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(medication.name, style: AppTextStyle.titleMedium),
                SizedBox(height: SdSpacingConstant.h4),
                Text(addedLabel, style: AppTextStyle.bodySmall.secondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
