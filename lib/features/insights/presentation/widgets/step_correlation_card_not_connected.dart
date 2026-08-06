part of 'step_correlation_card.dart';

/// No Apple Health, no analysis. The connect switch lives in Settings and
/// stays there: the HealthKit prompt is asked once, next to the sentence
/// explaining what is read, not from a card the user scrolled past.
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
