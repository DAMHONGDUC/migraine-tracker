part of 'settings_screen.dart';

/// The GDPR wipe (hard rule 8). Sits with the export rows, but its error
/// tint and confirm dialog keep it from being mistaken for one.
///
/// Says "local" without an account, because on device is all there is —
/// nothing was ever synced, so promising more than that overstates it.
///
/// While it runs the row's end carries a spinner and how far it has got, the
/// same pair the sync row shows: a wipe reaches the network, the OS scheduler
/// and several tables, so it can take long enough that a row which only spins
/// cannot tell slow from stuck.
class _DeleteAllTile extends ConsumerWidget {
  const _DeleteAllTile();

  Future<void> _deleteAll(
    BuildContext context,
    WidgetRef ref,
    bool signedIn,
  ) async {
    final AppLocalizations l10n = context.l10n;

    if (ref.read(settingsControllerProvider).isRunning) return;

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

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(settingsControllerProvider.notifier).deleteAll();

      if (context.mounted) {
        SdSnackBarUtilsV2.success(context, l10n.settingsDeleteDone);
      }
    } catch (_) {
      // The wipe aborts at the first failure rather than half-running, so
      // there is something to say beyond "it broke": nothing went.
      if (context.mounted) {
        SdSnackBarUtilsV2.error(context, l10n.settingsDeleteFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final bool signedIn = ref.watch(isSignedInProvider);
    final WipeStatus status = ref.watch(settingsControllerProvider);

    return SettingsTile(
      icon: AppIconConstant.deleteForever,
      titleColor: context.colorScheme.error,
      title: signedIn ? l10n.settingsDelete : l10n.settingsDeleteLocal,
      trailing: status.isRunning
          ? SettingsRowProgress(percent: status.percent)
          : null,
      onTap: () => _deleteAll(context, ref, signedIn),
    );
  }
}
