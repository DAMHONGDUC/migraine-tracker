part of 'login_screen.dart';

/// What an account is for, and what it does not do with health data.
/// `const`, so the sign-in state machine below never rebuilds it.
class _Pitch extends StatelessWidget {
  const _Pitch();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(height: AppSpacingConstant.h24),
        AppIcon(
          Icons.cloud_done_outlined,
          size: AppSpacingConstant.r64,
          color: context.colorScheme.primary,
        ),
        SizedBox(height: AppSpacingConstant.h16),
        Text(
          l10n.loginHeadline,
          textAlign: TextAlign.center,
          style: AppTextStyle.headlineSmall.w600,
        ),
        SizedBox(height: AppSpacingConstant.h8),
        Text(
          l10n.loginBody,
          textAlign: TextAlign.center,
          style: AppTextStyle.bodyMedium.secondary,
        ),
        SizedBox(height: AppSpacingConstant.h32),
        AppBenefitRow(
          icon: Icons.devices_outlined,
          title: l10n.loginBenefitDevices,
          body: l10n.loginBenefitDevicesBody,
        ),
        AppBenefitRow(
          icon: Icons.restore,
          title: l10n.loginBenefitRestore,
          body: l10n.loginBenefitRestoreBody,
        ),
        const _PrivacyDisclosure(),
      ],
    );
  }
}
