part of 'step_correlation_body.dart';

class _StepNoVariationBody extends StatelessWidget {
  const _StepNoVariationBody();

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.insightsStepsNoVariation,
      style: AppTextStyle.bodyMedium,
    );
  }
}
