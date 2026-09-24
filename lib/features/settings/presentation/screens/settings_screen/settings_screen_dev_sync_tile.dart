part of 'settings_screen.dart';

/// Dev-only: a whole sync pass now, from scratch, so the sync card's progress can be watched.
class _DevSyncTile extends ConsumerStatefulWidget {
  const _DevSyncTile();

  @override
  ConsumerState<_DevSyncTile> createState() => _DevSyncTileState();
}

class _DevSyncTileState extends ConsumerState<_DevSyncTile> {
  bool _running = false;

  Future<void> _sync() async {
    final AppLocalizations l10n = context.l10n;

    if (_running) return;

    setState(() => _running = true);
    try {
      final bool synced = await ref
          .read(syncControllerProvider.notifier)
          .syncEverythingNow();

      if (!mounted) return;
      if (synced) {
        SdSnackBarUtilsV2.success(context, l10n.settingsDevSyncDone);
      } else {
        SdSnackBarUtilsV2.error(context, l10n.settingsDevSyncFailed);
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return SettingsTile(
      icon: AppIconConstant.syncing,
      iconColor: AppColors.secondary,
      title: l10n.settingsDevSync,
      trailing: _running
          ? SizedBox(
              width: SdSpacingConstant.r20,
              height: SdSpacingConstant.r20,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _sync,
    );
  }
}
