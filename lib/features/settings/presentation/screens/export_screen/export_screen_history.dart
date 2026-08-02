part of 'export_screen.dart';

/// The list of past exports, newest first, narrowed to the picked date window.
/// Streams from Drift, so a new export appears the moment it is recorded.
///
/// Three states, not two: nothing exported yet ([_EmptyState], no filter to
/// offer), a window that matches nothing ([_NoMatchState], with the pill still
/// there to widen or clear it), or the rows.
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
              left: SdSpacingV2.w24,
              right: SdSpacingV2.w24,
              bottom: SdSpacingV2.h8,
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
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
