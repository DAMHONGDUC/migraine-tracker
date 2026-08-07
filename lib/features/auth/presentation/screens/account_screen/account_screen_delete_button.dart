part of 'account_screen.dart';

/// Deletes the account and everything in it (App Store 5.1.1(v)).
///
/// Deliberately separate from Settings' "Delete all data": someone clearing
/// their history usually wants to carry on using the app, and losing the
/// account would unbind their subscription with it.
class _DeleteAccountButton extends ConsumerWidget {
  const _DeleteAccountButton();

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;
    final bool? confirmed = await showSdDialogV2<bool>(
      context,
      builder: (BuildContext dialogContext) => SdDialogV2(
        title: l10n.accountDeleteConfirmTitle,
        content: Text(
          l10n.accountDeleteConfirmBody,
          style: AppTextStyle.bodyMedium,
        ),
        actions: <Widget>[
          SdButtonV2(
            variant: SdButtonVariantV2.text,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: l10n.commonCancel,
          ),
          SdButtonV2(
            variant: SdButtonVariantV2.destructive,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            label: l10n.accountDeleteConfirmAction,
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await ref.read(accountControllerProvider).deleteAccount();

      // This screen assumes an account; without one it would sit empty.
      if (context.mounted) {
        context.pop();
        SdSnackBarUtilsV2.success(context, l10n.accountDeleteDone);
      }
    } catch (_) {
      // The account survives a failure, so retrying is the right advice.
      if (context.mounted) {
        SdSnackBarUtilsV2.error(context, l10n.accountDeleteFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SdButtonV2(
      variant: SdButtonVariantV2.destructive,
      onPressed: () => _delete(context, ref),
      label: context.l10n.accountDelete,
      icon: Icons.delete_forever_outlined,
    );
  }
}
