part of 'export_screen.dart';

/// One past export: what it is, when it was made, how big it is. Tapping it
/// opens the actions sheet — share, save to device, delete.
class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record, required this.onTap});

  final ExportRecord record;
  final VoidCallback onTap;

  /// Local time: the user made this export on their own clock, not UTC.
  static final DateFormat _format = DateFormat.yMMMd().add_Hm();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final String subtitle =
        '${_format.format(record.createdAt.toLocal())}'
        ' · ${FileSizeUtils.format(l10n, record.sizeBytes)}';

    return ListTile(
      leading: AppIcon(record.kind.icon, color: context.colorScheme.primary),
      title: Text(record.kind.label(l10n), style: AppTextStyle.bodyLarge),
      subtitle: Text(subtitle, style: AppTextStyle.bodyMedium.secondary),
      trailing: AppIcon(
        Icons.more_horiz,
        size: AppSpacingConstant.r20,
        color: context.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
