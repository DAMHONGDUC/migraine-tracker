part of 'sleep_correlation_card.dart';

class _SleepNoVariationBody extends StatelessWidget {
  const _SleepNoVariationBody();

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.insightsSleepNoVariation,
      style: AppTextStyle.bodyMedium,
    );
  }
}
