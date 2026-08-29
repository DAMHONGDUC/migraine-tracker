part of 'settings_screen.dart';

/// The two Apple Health sources, with the switch that grants each one, and
/// one line saying what is read and where it stays.
///
/// **It exists to be found.** The switches also live on `/sleep` and
/// `/activity`, next to the readings they feed — that stays, it is where a
/// user changes their mind. But those screens are two taps in behind rows
/// named "Sleep" and "Activity", so nothing at the top level of the app said
/// the words "Apple Health" at all, and submission 1.0(11) was rejected under
/// App Store 2.5.1 for not identifying HealthKit in the UI. Same widget and
/// same provider as the detail screens, so the two surfaces cannot come to
/// disagree about what is connected.
///
/// Absent entirely off iOS, heading included — there is no HealthKit there
/// (see `healthAvailableProvider`), and a heading over nothing reads as a
/// screen that failed to load.
class _HealthSection extends ConsumerWidget {
  const _HealthSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    return Column(
      children: <Widget>[
        HealthConnectionTile(
          kind: HealthDataKind.sleep,
          icon: AppIconConstant.sleep,
          title: l10n.healthSleepTitle,
        ),
        HealthConnectionTile(
          kind: HealthDataKind.steps,
          icon: AppIconConstant.steps,
          title: l10n.healthStepsTitle,
        ),
        // The list is full-bleed for its ListTiles, so the one non-row here
        // puts the gutter back itself.
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SdContentPaddingV2.horizontal,
            vertical: SdSpacingConstant.h8,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.settingsHealthCaption,
              style: AppTextStyle.bodySmall.secondary,
            ),
          ),
        ),
      ],
    );
  }
}
