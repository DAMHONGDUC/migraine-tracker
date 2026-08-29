part of 'medication_detail_screen.dart';

/// How often this medication worked — the thing that turns the list from a record of what was taken into something a prescription changes on.
class _Effectiveness extends ConsumerWidget {
  const _Effectiveness({required this.medicationName});

  final String medicationName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final MedicationEffectiveness? row = ref.watch(
      medicationEffectivenessRowProvider(medicationName),
    );

    if (row == null || row.answeredCount == 0) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SdContentPaddingV2.horizontal,
        ),
        child: Text(
          l10n.medicationEffectNoAnswers,
          style: AppTextStyle.bodyMedium.secondary,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SdContentPaddingV2.horizontal),
      child: SdCardV2(
        child: Padding(
          padding: EdgeInsets.all(SdSpacingConstant.w20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(row.reliefLabel(l10n), style: AppTextStyle.titleMedium),
              SizedBox(height: SdSpacingConstant.h8),
        // The breakdown distinguishes partial relief from no relief.
              Text(
                <String>[
                  '${l10n.medicationEffectHelped}: ${row.helpedCount}',
                  '${l10n.medicationEffectPartly}: ${row.partlyCount}',
                  '${l10n.medicationEffectDidNotHelp}: ${row.didNotHelpCount}',
                ].join(' · '),
                style: AppTextStyle.bodyMedium.secondary,
              ),
              // What the attacks it was taken for actually looked like.
              if (row.typicalLabel(l10n) case final String typical) ...<Widget>[
                SizedBox(height: SdSpacingConstant.h8),
                Text(typical, style: AppTextStyle.bodySmall.secondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
