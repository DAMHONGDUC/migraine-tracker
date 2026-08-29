part of 'onboarding_screen.dart';

class _LocationPage extends StatelessWidget {
  const _LocationPage({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      icon: AppIconConstant.location,
      title: l10n.onboardingLocationTitle,
      body: l10n.onboardingLocationBody,
    );
  }
}
