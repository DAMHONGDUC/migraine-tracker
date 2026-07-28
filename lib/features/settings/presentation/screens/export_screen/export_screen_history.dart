part of 'export_screen.dart';

/// The list of past exports, newest first. Streams from Drift, so a new
/// export appears the moment it is recorded.
class _History extends ConsumerWidget {
  const _History({required this.onRecordTap});

  final ValueChanged<ExportRecord> onRecordTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final AsyncValue<List<ExportRecord>> history = ref.watch(
      exportHistoryProvider,
    );

    return switch (history) {
      AsyncData(value: final List<ExportRecord> records) when records.isEmpty =>
        const _EmptyState(),
      AsyncData(value: final List<ExportRecord> records) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
              left: AppSpacingConstant.w24,
              right: AppSpacingConstant.w24,
              bottom: AppSpacingConstant.h8,
            ),
            child: Text(
              l10n.exportHistoryTitle,
              style: AppTextStyle.titleSmall.secondary,
            ),
          ),
          for (final ExportRecord record in records)
            _RecordTile(record: record, onTap: () => onRecordTap(record)),
        ],
      ),
      AsyncError() => const _EmptyState(),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
