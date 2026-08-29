part of 'step_correlation_body.dart';

/// No Apple Health, no analysis.
class _StepNotConnected extends StatelessWidget {
  const _StepNotConnected();

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.insightsStepsNotConnected,
      style: AppTextStyle.bodyMedium,
    );
  }
}
