part of 'settings_screen.dart';

/// Dev-only: throw every record away and stay where you are, so the app redraws with the empty states a first launch shows.
///
/// [_DevResetTile] next to it does this *and* replays onboarding; this one is how an empty screen gets looked at without a fresh install.
class _DevDeleteDataTile extends ConsumerStatefulWidget {
  const _DevDeleteDataTile();

  @override
  ConsumerState<_DevDeleteDataTile> createState() => _DevDeleteDataTileState();
}

class _DevDeleteDataTileState extends ConsumerState<_DevDeleteDataTile> {
  bool _running = false;

  Future<void> _deleteAll() async {
    final AppLocalizations l10n = context.l10n;

    if (_running) return;

    final bool? confirmed = await showSdDialogV2<bool>(
      context,
      builder: (BuildContext dialogContext) => SdDialogV2(
        title: l10n.settingsDevDeleteDataConfirmTitle,
        content: Text(
          l10n.settingsDevDeleteDataConfirmBody,
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
            label: l10n.settingsDevDeleteDataConfirmAction,
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _running = true);
    try {
      await ref.read(settingsControllerProvider).deleteAllData();
      if (mounted) {
        SdSnackBarUtilsV2.success(context, l10n.settingsDevDeleteDataDone);
      }
    } catch (_) {
      if (mounted) {
        SdSnackBarUtilsV2.error(context, l10n.settingsDevDeleteDataFailed);
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return SettingsTile(
      icon: AppIconConstant.deleteForever,
      titleColor: context.colorScheme.error,
      title: l10n.settingsDevDeleteData,
      trailing: _running
          ? SizedBox(
              width: SdSpacingConstant.r20,
              height: SdSpacingConstant.r20,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _deleteAll,
    );
  }
}
