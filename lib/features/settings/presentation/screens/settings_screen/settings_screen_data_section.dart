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
        ListTile(
          leading: const AppIcon(Icons.ios_share),
          title: Text(l10n.settingsExport, style: AppTextStyle.bodyLarge),
          trailing: AppIcon(
            Icons.chevron_right,
            size: AppSpacingConstant.r20,
            color: context.colorScheme.onSurfaceVariant,
          ),
          onTap: () => context.pushNamed(AppRoutes.export.name),
        ),
        const _DeleteAllTile(),
      ],
    );
  }
}
