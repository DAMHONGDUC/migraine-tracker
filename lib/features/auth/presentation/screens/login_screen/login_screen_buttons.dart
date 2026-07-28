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
          AppButton(
            variant: AppButtonVariant.primary,
            onPressed: state.isBusy
                ? null
                : () => onSignIn(AuthProviderKind.apple),
            icon: SimpleIcons.apple,
            label: l10n.loginApple,
          ),
          SizedBox(height: AppSpacingConstant.h12),
        ],
        AppButton(
          variant: AppButtonVariant.outlined,
          onPressed: state.isBusy
              ? null
              : () => onSignIn(AuthProviderKind.google),
          icon: SimpleIcons.google,
          label: l10n.loginGoogle,
        ),
        // A calm bar under the buttons, not a spinner in the label.
        SizedBox(height: AppSpacingConstant.h8),
        SizedBox(
          height: AppSpacingConstant.h4,
          child: state.isBusy
              ? const LinearProgressIndicator()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
