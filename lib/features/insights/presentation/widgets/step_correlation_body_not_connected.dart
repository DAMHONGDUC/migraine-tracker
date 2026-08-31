part of 'step_correlation_body.dart';

/// No Apple Health, no analysis.
class _StepNotConnected extends StatelessWidget {
  const _StepNotConnected();

  @override
  Widget build(BuildContext context) {
    return SdEmptyStateV2(
      icon: AppIconConstant.steps,
      message: context.l10n.insightsStepsNotConnected,
      size: SdEmptyStateSizeV2.compact,
    );
  }
}
