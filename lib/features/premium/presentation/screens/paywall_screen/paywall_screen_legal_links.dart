part of 'paywall_screen.dart';

/// Terms of Use and Privacy Policy, side by side under the actions.
class _LegalLinks extends ConsumerWidget {
  const _LegalLinks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    // Wrap, not Row: side by side these overflowed the sheet by 23px in English and Vietnamese is longer again.
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

/// One link.
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

  /// Says so when the link will not open. The launcher never throws, so without this a failed tap is indistinguishable from a dead control.
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
