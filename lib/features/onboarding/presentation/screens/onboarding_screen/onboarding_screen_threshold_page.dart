part of 'onboarding_screen.dart';

class _ThresholdPage extends StatelessWidget {
  const _ThresholdPage({required this.l10n, required this.threshold});

  final AppLocalizations l10n;
  final ValueNotifier<double> threshold;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      icon: Icons.compress,
      title: l10n.onboardingThresholdTitle,
      body: l10n.onboardingThresholdBody,
      footer: ValueListenableBuilder<double>(
        valueListenable: threshold,
        builder: (context, value, _) => Column(
          children: [
            Text(
              l10n.onboardingThresholdValue(value.round()),
              style: AppTextStyle.displaySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.primary,
              ),
            ),
            Slider(
              value: value,
              min: 3,
              max: 10,
              divisions: 7,
              onChanged: (v) => threshold.value = v,
            ),
          ],
        ),
      ),
    );
  }
}
