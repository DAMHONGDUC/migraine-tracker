part of 'settings_screen.dart';

/// The two Apple Health sources, with the switch that grants each one, and one line saying what is read and where it stays.
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
        // The list is full-bleed for its ListTiles, so the one non-row here puts the gutter back itself.
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
