part of 'settings_screen.dart';

/// The GDPR wipe (hard rule 8). Lives at the end of "Your data" — it is the
/// same subject as the export rows, just the irreversible end of it — and
/// carries its own error tint and confirm dialog so it can never be
/// mistaken for one of them.
class _DeleteAllTile extends ConsumerWidget {
  const _DeleteAllTile();

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.settingsDeleteDone,
            style: AppTextStyle.bodyMedium,
          ),
        ),
      );
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
