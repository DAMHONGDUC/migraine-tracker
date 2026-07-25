part of 'login_screen.dart';

/// The provider buttons.
///
/// Apple sits first and gets the filled treatment: offering Google makes
/// Sign in with Apple mandatory (App Store 4.8), and Apple's guidelines
/// expect it to be no less prominent than the alternatives. It is hidden
/// entirely where the platform cannot serve it (Android, iOS < 13) rather
/// than shown as a button that only ever errors.
///
/// While a provider sheet is open both buttons go inert — two concurrent
/// sheets would race for the same anonymous UID to upgrade.
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
          AppButton.primary(
            onPressed: state.isBusy
                ? null
                : () => onSignIn(AuthProviderKind.apple),
            icon: Icons.apple,
            label: l10n.loginApple,
          ),
          SizedBox(height: AppSpacingConstant.h12),
        ],
        AppButton.outlined(
          onPressed: state.isBusy
              ? null
              : () => onSignIn(AuthProviderKind.google),
          label: l10n.loginGoogle,
        ),
        // Calm, non-flashing progress (hard rule 3): a bar that appears
        // under the buttons, rather than a spinner swapped into a label.
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
