part of 'account_screen.dart';

/// Deletes the account and everything in it (App Store 5.1.1(v)).
///
/// A row among the other rows, not a button in the action bar: the way out of
/// an account is taken once and hunted for deliberately, so it earns a line of
/// the list rather than permanent residence under the thumb, where it sat next
/// to Sign Out and the two read as a pair of equals.
class _DeleteAccountTile extends ConsumerStatefulWidget {
  const _DeleteAccountTile();

  @override
  ConsumerState<_DeleteAccountTile> createState() => _DeleteAccountTileState();
}

class _DeleteAccountTileState extends ConsumerState<_DeleteAccountTile> {
  bool _deleting = false;

  Future<void> _delete() async {
    final AppLocalizations l10n = context.l10n;

    if (_deleting) return;

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

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(accountControllerProvider).deleteAccount();

      // This screen assumes an account; without one it would sit empty.
      if (mounted) {
        context.pop();
        SdSnackBarUtilsV2.success(context, l10n.accountDeleteDone);
      }
    } on AuthException catch (e) {
      // Backing out of the Apple re-authorisation sheet is a change of mind, not a failure.
      if (e.error != AuthError.cancelled && mounted) {
        SdSnackBarUtilsV2.error(context, l10n.accountDeleteFailed);
      }
    } catch (_) {
      // The account survives a failure, so retrying is the right advice.
      if (mounted) SdSnackBarUtilsV2.error(context, l10n.accountDeleteFailed);
    } finally {
      // Skipped when it succeeded — the screen has popped by then.
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    // Red on the whole row, like Settings' destructive rows: the tint is the
    // warning, and the dialog behind the tap is what actually confirms it.
    return SettingsTile(
      icon: AppIconConstant.deleteForever,
      titleColor: context.colorScheme.error,
      title: _deleting ? l10n.commonDeleting : l10n.accountDelete,
      trailing: _deleting
          ? SizedBox.square(
              dimension: SdSpacingConstant.r20,
              child: CircularProgressIndicator(
                strokeWidth: SdSpacingConstant.w2,
                color: context.colorScheme.error,
              ),
            )
          : null,
      onTap: _deleting ? null : _delete,
    );
  }
}
