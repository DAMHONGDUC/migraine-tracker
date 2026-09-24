part of 'account_screen.dart';

/// Deletes the account and everything in it (App Store 5.1.1(v)).
///
/// A row among the other rows, not a button in the action bar: the way out of
/// an account is taken once and hunted for deliberately, so it earns a line of
/// the list rather than permanent residence under the thumb, where it sat next
/// to Sign Out and the two read as a pair of equals.
class _DeleteAccountTile extends ConsumerWidget {
  const _DeleteAccountTile({
    required this.deleting,
    required this.onDeletingChanged,
  });

  /// The screen's flag, not this row's: it also raises [_BusyOverlay].
  final bool deleting;
  final ValueChanged<bool> onDeletingChanged;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;

    if (deleting) return;

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

    if (confirmed != true || !context.mounted) return;

    onDeletingChanged(true);
    try {
      await ref.read(accountControllerProvider).deleteAccount();

      // This screen assumes an account; without one it would sit empty.
      if (context.mounted) {
        context.pop();
        SdSnackBarUtilsV2.success(context, l10n.accountDeleteDone);
      }
    } on AuthException catch (e) {
      // Backing out of the Apple re-authorisation sheet is a change of mind, not a failure.
      if (e.error != AuthError.cancelled && context.mounted) {
        SdSnackBarUtilsV2.error(context, l10n.accountDeleteFailed);
      }
    } catch (_) {
      // The account survives a failure, so retrying is the right advice.
      if (context.mounted) {
        SdSnackBarUtilsV2.error(context, l10n.accountDeleteFailed);
      }
    } finally {
      // The screen outlives this row's rebuild either way: on success it has
      // popped and the flag goes with it, on failure the overlay has to lift.
      if (context.mounted) onDeletingChanged(false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    // Red on the whole row, like Settings' destructive rows: the tint is the
    // warning, and the dialog behind the tap is what actually confirms it.
    return SettingsTile(
      icon: AppIconConstant.deleteForever,
      titleColor: context.colorScheme.error,
      title: deleting ? l10n.commonDeleting : l10n.accountDelete,
      trailing: deleting
          ? SizedBox.square(
              dimension: SdSpacingConstant.r20,
              child: CircularProgressIndicator(
                strokeWidth: SdSpacingConstant.w2,
                color: context.colorScheme.error,
              ),
            )
          : null,
      onTap: deleting ? null : () => _delete(context, ref),
    );
  }
}

/// The screen, out of reach, while the server works.
///
/// A scrim with a spinner card over it, like a dialog, rather than a disabled row: deleting an account is a
/// Cloud Function round trip, and signing out pushes what the device still
/// owes before it wipes the device's copy. Every control still live during
/// either — Sign Out, edit name, the back arrow — acts on an account that may
/// be gone, or on data that is about to be.
class _BusyOverlay extends StatelessWidget {
  const _BusyOverlay({this.message});

  /// Shown under the spinner when the wait needs a name. Null for the delete, where the row that started it already says "Deleting…".
  final String? message;

  /// Big enough to read as the screen's own wait, not a row's.
  static double get spinnerSize => SdSpacingConstant.r28;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: <Widget>[
          // The same barrier a dialog puts up, and for the same reason: it swallows the taps.
          ModalBarrier(color: context.sdTheme.barrier, dismissible: false),
          // A card of its own, like a dialog: it sits outside the scaffold, so this Material is also what gives the text its theme — without it Flutter draws the yellow "no Material" underline.
          Center(
            child: Material(
              color: context.sdTheme.surfaceModal,
              borderRadius: BorderRadius.circular(SdCardV2.radius),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SdSpacingConstant.w24,
                  vertical: SdSpacingConstant.h20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox.square(
                      dimension: spinnerSize,
                      child: CircularProgressIndicator(
                        strokeWidth: SdSpacingConstant.w2,
                        color: context.colorScheme.primary,
                      ),
                    ),
                    if (message != null) ...<Widget>[
                      SizedBox(height: SdSpacingConstant.h16),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: SdSpacingConstant.w240,
                        ),
                        child: Text(
                          message!,
                          textAlign: TextAlign.center,
                          style: AppTextStyle.bodyMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
