part of 'sleep_correlation_body.dart';

/// No Apple Health, no analysis.
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
