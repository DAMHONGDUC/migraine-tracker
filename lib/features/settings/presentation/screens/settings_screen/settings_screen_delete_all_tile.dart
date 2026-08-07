part of 'settings_screen.dart';

/// The GDPR wipe (hard rule 8). Sits with the export rows, but its error
/// tint and confirm dialog keep it from being mistaken for one.
///
/// Says "local" without an account, because on device is all there is —
/// nothing was ever synced, so promising more than that overstates it.
class _DeleteAllTile extends ConsumerStatefulWidget {
  const _DeleteAllTile();

  @override
  ConsumerState<_DeleteAllTile> createState() => _DeleteAllTileState();
}

class _DeleteAllTileState extends ConsumerState<_DeleteAllTile> {
  bool _running = false;

  Future<void> _deleteAll(bool signedIn) async {
    final AppLocalizations l10n = context.l10n;

    if (_running) return;

    final bool? confirmed = await showSdDialogV2<bool>(
      context,
      builder: (BuildContext dialogContext) => SdDialogV2(
        title: l10n.settingsDeleteConfirmTitle,
        content: Text(
          signedIn
              ? l10n.settingsDeleteConfirmBody
              : l10n.settingsDeleteLocalConfirmBody,
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
            label: l10n.settingsDeleteConfirmAction,
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _running = true);
    try {
      await ref.read(settingsControllerProvider).deleteAll();

      if (mounted) SdSnackBarUtilsV2.success(context, l10n.settingsDeleteDone);
    } catch (_) {
      // The wipe aborts at the first failure rather than half-running, so
      // there is something to say beyond "it broke": nothing went.
      if (mounted) SdSnackBarUtilsV2.error(context, l10n.settingsDeleteFailed);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool signedIn = ref.watch(isSignedInProvider);

    return SettingsTile(
      icon: Icons.delete_forever_outlined,
      titleColor: context.colorScheme.error,
      title: signedIn ? l10n.settingsDelete : l10n.settingsDeleteLocal,
      trailing: _running
          ? SizedBox(
              width: SdSpacingConstant.r20,
              height: SdSpacingConstant.r20,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: () => _deleteAll(signedIn),
    );
  }
}
