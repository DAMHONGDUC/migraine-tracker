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
      // Same control as the attack detail's intensity dialog, and the same
      // severity ramp on the number: a bigger drop is the one worth warning
      // about, so it reads redder as it climbs.
      footer: ValueListenableBuilder<double>(
        valueListenable: threshold,
        builder: (BuildContext context, double value, _) => SdValueSliderV2(
          label: l10n.onboardingThresholdValue(value.round()),
          value: value,
          min: 3,
          max: 10,
          divisions: 7,
          accent: AppColors.intensity(value.round()),
          onChanged: (double v) => threshold.value = v,
        ),
      ),
    );
  }
}
