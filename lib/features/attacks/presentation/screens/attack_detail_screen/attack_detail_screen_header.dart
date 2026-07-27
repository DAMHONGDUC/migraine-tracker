part of 'attack_detail_screen.dart';

class _Header extends StatelessWidget {
  const _Header({required this.attack});

  final Attack attack;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.intensity(attack.intensity);
    final when = DateFormat.yMMMMEEEEd(
      context.l10n.localeName,
    ).add_jm().format(attack.startedAt.toLocal());

    return Row(
      children: [
        Container(
          width: AppSpacingConstant.r64,
          height: AppSpacingConstant.r64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.45),
            border: Border.all(color: color, width: 1.5),
          ),
          child: FittedBox(
            child: Text(
              '${attack.intensity}',
              style: AppTextStyle.headlineSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        SizedBox(width: AppSpacingConstant.w16),
        Expanded(child: Text(when, style: AppTextStyle.titleMedium)),
      ],
    );
  }
}
