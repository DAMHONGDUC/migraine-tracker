part of 'sleep_correlation_body.dart';

/// No Apple Health, no analysis. The connect switch lives in Settings and
/// stays there: the HealthKit prompt is asked once, next to the sentence
/// explaining what is read, not from a card the user scrolled past.
class _NotConnected extends StatelessWidget {
  const _NotConnected();

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.insightsSleepNotConnected,
      style: AppTextStyle.bodyMedium,
    );
  }
}
