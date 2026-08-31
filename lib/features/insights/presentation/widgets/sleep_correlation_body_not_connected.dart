part of 'sleep_correlation_body.dart';

/// No Apple Health, no analysis.
class _NotConnected extends StatelessWidget {
  const _NotConnected();

  @override
  Widget build(BuildContext context) {
    return SdEmptyStateV2(
      icon: AppIconConstant.sleep,
      message: context.l10n.insightsSleepNotConnected,
      size: SdEmptyStateSizeV2.compact,
    );
  }
}
