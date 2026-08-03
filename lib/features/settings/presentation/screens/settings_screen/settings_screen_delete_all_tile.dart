part of 'settings_screen.dart';

/// The GDPR wipe (hard rule 8). Sits with the export rows, but its error
/// tint and confirm dialog keep it from being mistaken for one.
class _DeleteAllTile extends ConsumerWidget {
  const _DeleteAllTile();

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showSdDialogV2<bool>(
      context,
      builder: (dialogContext) => SdDialogV2(
        title: l10n.settingsDeleteConfirmTitle,
        content: Text(
          l10n.settingsDeleteConfirmBody,
          style: AppTextStyle.bodyMedium,
        ),
        actions: [
          SdButtonV2(
            variant: SdButtonVariantV2.text,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            label: l10n.commonCancel,
          ),
          SdButtonV2(
            variant: SdButtonVariantV2.destructive,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            label: l10n.settingsDeleteConfirmAction,
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(settingsControllerProvider).deleteAll();
    if (context.mounted) {
      SdSnackBarUtilsV2.success(context, l10n.settingsDeleteDone);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return ListTile(
      leading: SdIconV2(
        icon: Icons.delete_forever_outlined,
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
