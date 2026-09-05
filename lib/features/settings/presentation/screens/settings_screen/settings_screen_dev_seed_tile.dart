part of 'settings_screen.dart';

/// Dev-only: throw the database away and refill it with fixtures.
class _DevSeedTile extends ConsumerStatefulWidget {
  const _DevSeedTile();

  @override
  ConsumerState<_DevSeedTile> createState() => _DevSeedTileState();
}

class _DevSeedTileState extends ConsumerState<_DevSeedTile> {
  bool _running = false;

  Future<void> _seed() async {
    final AppLocalizations l10n = context.l10n;

    if (_running) return;

    setState(() => _running = true);
    try {
      await ref.read(settingsControllerProvider).seedDevData();
      if (mounted) {
        SdSnackBarUtilsV2.success(context, l10n.settingsDevSeedDone);
      }
    } catch (_) {
      if (mounted) {
        SdSnackBarUtilsV2.error(context, l10n.settingsDevSeedFailed);
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return SettingsTile(
      icon: AppIconConstant.devTool,
      iconColor: AppColors.secondary,
      title: l10n.settingsDevSeed,
      trailing: _running
          ? SizedBox(
              width: SdSpacingConstant.r20,
              height: SdSpacingConstant.r20,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _seed,
    );
  }
}
