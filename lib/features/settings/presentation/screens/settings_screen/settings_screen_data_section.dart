part of 'settings_screen.dart';

/// Get the data out, or destroy it. **Export is premium in full now** — the
/// JSON and CSV exports as well as the doctor report — so the row wears the
/// badge and `NavigationUtils.toExport` holds the gate. The wipe stays free:
/// hard rule 8 makes deleting everything a promise, never an upsell.
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
          icon: Icons.ios_share,
          title: l10n.settingsExport,
          child: SettingsTile(
            icon: Icons.ios_share,
            title: l10n.settingsExport,
            onTap: () => NavigationUtils.toExport(context, ref),
          ),
        ),
        const _DeleteAllTile(),
      ],
    );
  }
}
