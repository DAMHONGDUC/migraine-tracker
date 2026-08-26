part of 'medication_detail_screen.dart';

/// How often this medication worked — the thing that turns the list from a
/// record of what was taken into something a prescription changes on.
///
/// States "helped X of Y", where Y counts only the attacks whose outcome the
/// user actually answered. An unanswered attack is not a failure, and
/// counting it as one would make every drug look worse the less diligent
/// somebody is about logging.
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
              // The breakdown, because "helped 8 of 10" hides whether the
              // other two did nothing or took the edge off — which is the
              // difference between changing the drug and changing the dose.
              Text(
                <String>[
                  '${l10n.medicationEffectHelped}: ${row.helpedCount}',
                  '${l10n.medicationEffectPartly}: ${row.partlyCount}',
                  '${l10n.medicationEffectDidNotHelp}: ${row.didNotHelpCount}',
                ].join(' · '),
                style: AppTextStyle.bodyMedium.secondary,
              ),
              // What the attacks it was taken for actually looked like. Two
              // drugs cannot be read against each other without it: the one
              // kept for the worst attacks would otherwise just look weaker.
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
