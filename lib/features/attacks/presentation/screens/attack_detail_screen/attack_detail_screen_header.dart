part of 'attack_detail_screen.dart';

class _Header extends StatelessWidget {
  const _Header({required this.attack});

  final Attack attack;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat.yMMMMEEEEd(
      context.l10n.localeName,
    ).add_jm().format(attack.startedAt.toLocal());

    return Row(
      children: [
        IntensityDisc(
          value: attack.intensity,
          size: SdSpacingConstant.r64,
        ),
        SizedBox(width: SdSpacingConstant.w16),
        Expanded(child: Text(when, style: AppTextStyle.titleMedium)),
      ],
    );
  }
}
