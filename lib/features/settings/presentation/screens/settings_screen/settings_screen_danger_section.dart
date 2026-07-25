part of 'settings_screen.dart';

/// The irreversible one, alone under its own heading so it cannot be
/// mistaken for the export rows above it (hard rule 8 — GDPR wipe).
class _DangerSection extends ConsumerWidget {
  const _DangerSection();

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showAppDialog<bool>(
      context,
      builder: (dialogContext) => AppDialog(
        title: l10n.settingsDeleteConfirmTitle,
        content: Text(
          l10n.settingsDeleteConfirmBody,
          style: AppTextStyle.bodyMedium,
        ),
        actions: [
          AppButton.text(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: l10n.commonCancel,
          ),
          AppButton.destructive(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            label: l10n.settingsDeleteConfirmAction,
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(settingsControllerProvider).deleteAll();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsDeleteDone)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return ListTile(
      leading: AppIcon(
        Icons.delete_forever_outlined,
        color: context.colorScheme.error,
      ),
      title: Text(
        l10n.settingsDelete,
        style: AppTextStyle.bodyLarge.copyWith(
          color: context.colorScheme.error,
        ),
      ),
      onTap: () => _deleteAll(context, ref),
    );
  }
}
