part of 'settings_screen.dart';

/// Dev-only: throw the database away and refill it with fixtures. The whole
/// section is compiled out of a prod flavour by its `!AppEnv.isProd` guard,
/// so there is no confirm dialog — nobody real can reach it.
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
        SdSnackBarUtilsV2.success(
          context,
          l10n.settingsDevSeedDone(DevSeedService.seedCount),
        );
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

    return ListTile(
      leading: const SdIconV2(
        icon: Icons.science_outlined,
        color: AppColors.secondary,
      ),
      title: Text(l10n.settingsDevSeed, style: AppTextStyle.bodyLarge),
      subtitle: Text(
        l10n.settingsDevSeedSubtitle(DevSeedService.seedCount),
        style: AppTextStyle.bodyMedium.secondary,
      ),
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
