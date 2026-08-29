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
        // Starts flush: SdActionViewV2 already applied the screen's top gap.
        SdIconV2(
          icon: AppIconConstant.synced,
          size: AppIconSize.display,
          color: context.colorScheme.primary,
        ),
        SizedBox(height: SdSpacingConstant.h16),
        Text(
          l10n.loginHeadline,
          textAlign: TextAlign.center,
          style: AppTextStyle.headlineSmall.w600,
        ),
        SizedBox(height: SdSpacingConstant.h8),
        Text(
          l10n.loginBody,
          textAlign: TextAlign.center,
          style: AppTextStyle.bodyMedium.secondary,
        ),
        SizedBox(height: SdSpacingConstant.h32),
        SdBenefitRowV2(
          icon: AppIconConstant.devices,
          title: l10n.loginBenefitDevices,
          body: l10n.loginBenefitDevicesBody,
        ),
        SdBenefitRowV2(
          icon: AppIconConstant.restore,
          title: l10n.loginBenefitRestore,
          body: l10n.loginBenefitRestoreBody,
        ),
        const _PrivacyDisclosure(),
      ],
    );
  }
}
