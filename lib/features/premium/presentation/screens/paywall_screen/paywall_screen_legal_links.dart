part of 'paywall_screen.dart';

/// Terms of Use and Privacy Policy, side by side under the actions.
///
/// **Required in the binary, not just the listing.** App Store guideline 3.1.2
/// wants both links wherever an auto-renewable subscription is sold, and a
/// submission was already rejected for the metadata half of the same rule —
/// so this is the half that would have been caught next.
///
/// Shown to everyone the paywall is shown to, signed in or not: the links
/// describe what the subscription is sold under, which someone deciding
/// whether to sign in has the most reason to read.
class _LegalLinks extends ConsumerWidget {
  const _LegalLinks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    // Wrap, not Row: side by side these overflowed the sheet by 23px in
    // English and Vietnamese is longer again. A link a reviewer cannot read is
    // one they cannot follow, so they stack rather than clip.
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: SdSpacingConstant.w16,
      runSpacing: SdSpacingConstant.h4,
      children: <Widget>[
        _LegalLink(
          label: l10n.paywallTermsOfUse,
          url: LegalUrlConstant.termsOfUse,
        ),
        _LegalLink(
          label: l10n.paywallPrivacyPolicy,
          url: LegalUrlConstant.privacyPolicy,
        ),
      ],
    );
  }
}

/// Restore, and the optional sign-in — tappable text under the CTA rather
/// than buttons (owner's call).
///
/// **Same reasoning as [_LegalLink] below, one step up in emphasis.** Three
/// stacked buttons made the sheet read as three offers of equal weight, when
/// only one of them is the purchase. These carry the body colour rather than
/// the footnote's grey, and keep a full-width `h12` inset so the tap target
/// stays finger-sized once the button's own padding is gone — a restore path
/// a reviewer cannot hit is App Store 3.1.1 unmet.
class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SdPressableScaleV2(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h12),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyle.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// One link. Deliberately not an [SdButtonV2]: a pair of filled or outlined
/// buttons under the CTA would compete with it, and these are a footnote the
/// reviewer must be able to tap, not a second call to action.
class _LegalLink extends ConsumerWidget {
  const _LegalLink({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SdPressableScaleV2(
      onTap: () => unawaited(_open(context, ref)),
      child: Text(
        label,
        style: AppTextStyle.bodySmall.copyWith(
          color: AppColors.textSecondary,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.textSecondary,
        ),
      ),
    );
  }

  /// Says so when the link will not open. The launcher never throws, so
  /// without this a failed tap is indistinguishable from a dead control.
  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;
    final bool opened = await ref.read(linkLauncherProvider).open(url);

    if (opened || !context.mounted) return;

    SdSnackBarUtilsV2.error(
      context,
      l10n.paywallLinkFailed,
      placement: PaywallScreen._placement,
    );
  }
}
