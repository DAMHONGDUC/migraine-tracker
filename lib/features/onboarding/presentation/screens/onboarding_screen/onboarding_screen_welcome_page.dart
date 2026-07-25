part of 'onboarding_screen.dart';

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      icon: Icons.storm_outlined,
      title: l10n.onboardingWelcomeTitle,
      body: l10n.onboardingWelcomeBody,
      footer: Container(
        padding: EdgeInsets.all(AppSpacingConstant.w16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacingConstant.r12),
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(
              Icons.info_outline,
              size: AppSpacingConstant.r20,
              color: context.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: AppSpacingConstant.w12),
            Expanded(
              child: Text(
                l10n.onboardingDisclaimer,
                style: AppTextStyle.bodySmall.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
