part of 'subscription_screen.dart';

/// Opens the store's own subscription page, which is the only place a subscription can be cancelled or switched.
///
/// Absent until the store hands back a page to open: an account made premium by
/// the `app_access` allow-list has no purchase behind it, and a button onto
/// nothing reads as broken where the note beside it already says where to go.
class _ManageButton extends ConsumerWidget {
  const _ManageButton();

  /// Says so when the page will not open. The launcher never throws, so without this a failed tap is indistinguishable from a dead control.
  Future<void> _open(BuildContext context, WidgetRef ref, String url) async {
    final AppLocalizations l10n = context.l10n;

    SdLogger.info(
      LogTagConstant.purchase,
      'Opening the store subscription page',
      url,
    );

    final bool opened = await ref.read(linkLauncherProvider).open(url);

    SdLogger.info(
      LogTagConstant.purchase,
      'Store subscription page opened',
      opened,
    );

    if (opened || !context.mounted) return;

    SdSnackBarUtilsV2.error(context, l10n.paywallLinkFailed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Loading and failure land on the same branch as "nothing to manage": all three mean there is no page to send the user to yet.
    final String? url = switch (ref.watch(managementUrlProvider)) {
      AsyncData(value: final String? value) => value,
      _ => null,
    };

    if (url == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: SdSpacingConstant.h12),
      child: SdButtonV2(
        variant: SdButtonVariantV2.secondary,
        onPressed: () => unawaited(_open(context, ref, url)),
        label: context.l10n.premiumScreenManage,
      ),
    );
  }
}
