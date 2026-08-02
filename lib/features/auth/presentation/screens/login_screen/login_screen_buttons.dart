part of 'login_screen.dart';

/// Apple first and filled: Apple's guidelines want it no less prominent
/// than the alternatives. Hidden only where the platform cannot serve it —
/// it shows even while unimplemented, so the layout is final from the start
/// (see `appleSignInImplementedProvider`).
///
/// Both go inert while a sheet is open: two would race for the same
/// anonymous UID.
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
            iconPlacement: SdButtonIconPlacementV2.aligned,
            label: l10n.loginApple,
          ),
          SizedBox(height: SdSpacingV2.h12),
        ],
        SdButtonV2(
          variant: SdButtonVariantV2.outlined,
          onPressed: state.isBusy
              ? null
              : () => onSignIn(AuthProviderKind.google),
          icon: SimpleIcons.google,
          iconSize: SdSpacingV2.r18,
          iconPlacement: SdButtonIconPlacementV2.aligned,
          label: l10n.loginGoogle,
        ),
        // A calm bar under the buttons, not a spinner in the label.
        SizedBox(height: SdSpacingV2.h8),
        SizedBox(
          height: SdSpacingV2.h4,
          child: state.isBusy
              ? const LinearProgressIndicator()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
