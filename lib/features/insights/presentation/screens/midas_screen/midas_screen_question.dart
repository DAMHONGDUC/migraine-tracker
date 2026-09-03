part of 'midas_screen.dart';

/// One question and its day count. A stepper rather than a keyboard: every answer is a small number of days, and a numeric field mid-migraine is a keyboard over the question.
class _Question extends StatelessWidget {
  const _Question({
    required this.question,
    required this.note,
    required this.days,
    required this.onChanged,
  });

  final String question;
  final String? note;
  final int days;
  final ValueChanged<int> onChanged;

  /// The most days a three-month window can hold. Past it the answer is a typo, not a worse migraine.
  static const int maxDays = 92;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(question, style: AppTextStyle.titleSmall),
        if (note case final String text) ...<Widget>[
          SizedBox(height: SdSpacingConstant.h4),
          Text(
            text,
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        SizedBox(height: SdSpacingConstant.h8),
        Row(
          children: <Widget>[
            _StepButton(
              icon: Icons.remove_rounded,
              onTap: days > 0 ? () => onChanged(days - 1) : null,
            ),
            Expanded(
              child: Text(
                '$days',
                textAlign: TextAlign.center,
                style: AppTextStyle.titleMedium,
              ),
            ),
            _StepButton(
              icon: Icons.add_rounded,
              onTap: days < maxDays ? () => onChanged(days + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  /// Apple's minimum target, which is what a button holding one glyph should be.
  static const double size = 44;

  @override
  Widget build(BuildContext context) {
    final Color color = onTap == null
        ? AppColors.textSecondary.withValues(alpha: 0.4)
        : AppColors.primary;

    return SdPressableScaleV2(
      // A disabled step still takes the tap and does nothing: the button keeps its size and its place, and only its colour says it is spent.
      onTap: onTap ?? () {},
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(SdSpacingConstant.r16),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}

/// The running total and the grade it falls in, so the questionnaire answers itself as it is filled.
class _Total extends StatelessWidget {
  const _Total({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final MidasGrade grade = MidasEntry.gradeOf(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.midasScore(score),
          style: AppTextStyle.titleLarge.copyWith(color: AppColors.primary),
        ),
        SizedBox(height: SdSpacingConstant.h4),
        Text(
          grade.label(l10n),
          style: AppTextStyle.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
