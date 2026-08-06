part of 'settings_screen.dart';

/// Get the data out, or destroy it. Export is free forever (hard rule 8);
/// the doctor report is its premium flavour, gated inside the export screen
/// where the formats are picked.
class _DataSection extends ConsumerWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Column(
      children: [
        // Where the data goes, before what you can get out of it or destroy.
        const SyncSettingsTile(),
        SettingsTile(
          icon: Icons.ios_share,
          title: l10n.settingsExport,
          onTap: () => context.pushNamed(AppRoutes.export.name),
        ),
        const _DeleteAllTile(),
      ],
    );
  }
}
