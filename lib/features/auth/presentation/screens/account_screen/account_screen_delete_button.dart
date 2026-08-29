part of 'account_screen.dart';

/// Deletes the account and everything in it (App Store 5.1.1(v)).
///
/// Deliberately separate from Settings' "Delete all data": someone clearing
/// their history usually wants to carry on using the app, and losing the
/// account would unbind their subscription with it.
class _DeleteAccountButton extends ConsumerStatefulWidget {
  const _DeleteAccountButton();

  @override
  ConsumerState<_DeleteAccountButton> createState() =>
      _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends ConsumerState<_DeleteAccountButton> {
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
      // Backing out of the Apple re-authorisation sheet is a change of mind,
      // not a failure. Nothing is wiped by then — the revoke runs first for
      // exactly this reason — so there is nothing to report.
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

    // Outlined, not filled: this offers the deletion, the dialog confirms it.
    // Sign out above is filled, so the eye lands on the reversible action —
    // and the error tint still reads as the dangerous one, which plain did not.
    return SdButtonV2(
      variant: SdButtonVariantV2.outlinedDestructive,
      onPressed: _deleting ? null : _delete,
      label: _deleting ? l10n.commonDeleting : l10n.accountDelete,
      icon: AppIconConstant.deleteForever,
    );
  }
}
