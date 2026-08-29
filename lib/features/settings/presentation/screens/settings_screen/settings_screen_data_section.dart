part of 'settings_screen.dart';

/// Get the data out, or destroy it.
class _DataSection extends ConsumerWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Column(
      children: [
        // Where the data goes, before what you can get out of it or destroy.
        const SyncSettingsTile(),
        PremiumTileGate(
          icon: AppIconConstant.share,
          title: l10n.settingsExport,
          child: SettingsTile(
            icon: AppIconConstant.share,
            title: l10n.settingsExport,
            onTap: () => NavigationUtils.toExport(context, ref),
          ),
        ),
        const _DeleteAllTile(),
      ],
    );
  }
}
