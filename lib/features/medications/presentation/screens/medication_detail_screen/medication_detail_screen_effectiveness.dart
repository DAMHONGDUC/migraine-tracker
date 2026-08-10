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
    final MedicationEffectCount count = ref.watch(
      medicationEffectCountProvider(medicationName),
    );

    if (count.isEmpty) {
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
              Text(
                l10n.medicationEffectTally(count.helped, count.answered),
                style: AppTextStyle.titleMedium,
              ),
              SizedBox(height: SdSpacingConstant.h8),
              // The breakdown, because "helped 8 of 10" hides whether the
              // other two did nothing or took the edge off — which is the
              // difference between changing the drug and changing the dose.
              Text(
                <String>[
                  '${l10n.medicationEffectHelped}: ${count.helped}',
                  '${l10n.medicationEffectPartly}: ${count.partly}',
                  '${l10n.medicationEffectDidNotHelp}: ${count.didNotHelp}',
                ].join(' · '),
                style: AppTextStyle.bodyMedium.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
