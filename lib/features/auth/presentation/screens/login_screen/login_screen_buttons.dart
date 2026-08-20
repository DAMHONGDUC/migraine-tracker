part of 'login_screen.dart';

/// Apple first and filled: Apple's guidelines want it no less prominent
/// than the alternatives. Hidden only where the platform cannot serve it —
/// it shows even while unimplemented, so the layout is final from the start
/// (see `appleSignInImplementedProvider`).
///
/// Both go inert while a sheet is open: two would race for the same
/// anonymous UID.
///
/// **Glyph and label are centred as one cluster** — owner's rule: content
/// inside an app button is horizontally centred, full stop. These two used to
/// pass `SdButtonIconPlacementV2.aligned`, which start-aligns the label in a
/// fixed-width slot so both buttons put their glyphs on the same x and read as
/// a pair. It bought that pairing by leaving each button's visible ink sitting
/// left of its own centre, which is the thing the rule exists to prevent.
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
        // A calm bar under the buttons, not a spinner in the label.
        SizedBox(height: SdSpacingConstant.h8),
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
