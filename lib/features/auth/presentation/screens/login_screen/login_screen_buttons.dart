part of 'login_screen.dart';

/// Apple first and filled: Apple's guidelines want it no less prominent than the alternatives.
class _ProviderButtons extends ConsumerWidget {
  const _ProviderButtons({required this.state, required this.onSignIn});

  final LoginState state;
  final void Function(AuthProviderKind provider) onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool appleAvailable =
        ref.watch(isAppleSignInAvailableProvider).value ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (appleAvailable) ...<Widget>[
          SdButtonV2(
            variant: SdButtonVariantV2.primary,
            onPressed: state.isBusy
                ? null
                : () => onSignIn(AuthProviderKind.apple),
            icon: SimpleIcons.apple,
            label: l10n.loginApple,
          ),
          SizedBox(height: SdSpacingConstant.h12),
        ],
        SdButtonV2(
          variant: SdButtonVariantV2.outlined,
          onPressed: state.isBusy
              ? null
              : () => onSignIn(AuthProviderKind.google),
          icon: SimpleIcons.google,
          iconSize: SdSpacingConstant.r18,
          label: l10n.loginGoogle,
        ),
        SizedBox(
          height: SdSpacingConstant.h4,
          child: state.isBusy
              ? const LinearProgressIndicator()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
