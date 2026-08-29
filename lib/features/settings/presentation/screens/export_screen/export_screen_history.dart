part of 'export_screen.dart';

/// The list of past exports, newest first, narrowed to the picked date window.
class _History extends ConsumerWidget {
  const _History({required this.onRecordTap});

  final ValueChanged<ExportRecord> onRecordTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bool hasAny =
        ref.watch(exportHistoryProvider).value?.isNotEmpty ?? false;
    final AsyncValue<List<ExportRecord>> history = ref.watch(
      filteredExportHistoryProvider,
    );

    return switch (history) {
      AsyncData(value: final List<ExportRecord> records)
          when records.isEmpty && !hasAny =>
        const _EmptyState(),
      AsyncData(value: final List<ExportRecord> records) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(
              left: SdContentPaddingV2.horizontal,
              right: SdContentPaddingV2.horizontal,
              bottom: SdSpacingConstant.h8,
            ),
            child: Text(
              l10n.exportHistoryTitle,
              style: AppTextStyle.titleSmall.secondary,
            ),
          ),
          if (records.isEmpty)
            const _NoMatchState()
          else
            for (final ExportRecord record in records)
              _RecordTile(record: record, onTap: () => onRecordTap(record)),
        ],
      ),
      AsyncError() => const _EmptyState(),
      // Rows rather than a spinner: this sits under a heading in a column, so the block below it should not jump when the records arrive.
      _ => const SdListSkeletonV2(rows: 3),
    };
  }
}
