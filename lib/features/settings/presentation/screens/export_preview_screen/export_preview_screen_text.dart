part of 'export_preview_screen.dart';

/// A JSON or CSV export, read as what it is: CSV as a table, JSON as its own
/// unwrapped text.
///
/// Neither wraps. Wrapping is what made a 14-column CSV read as a wall of
/// words, and it does the same to indented JSON — both carry their meaning in
/// the line breaks the file already has.
class _TextBody extends ConsumerWidget {
  const _TextBody({required this.exportId, required this.filename});

  final String exportId;
  final String filename;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<ExportPreview> preview = ref.watch(
      exportPreviewProvider(exportId),
    );

    return switch (preview) {
      AsyncData<ExportPreview>(value: final ExportPreview value) => ListView(
        padding: SdContentPaddingV2.screen(context),
        children: <Widget>[
          Text(filename, style: AppTextStyle.bodyMedium.secondary),
          SizedBox(height: SdContentPaddingV2.listItemGap),
          SdCardV2(
            child: Padding(
              padding: EdgeInsets.all(SdSpacingConstant.w16),
              // Its own horizontal scroll: the content is wider than the
              // phone whichever format it is, and the page must not be.
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: value.rows == null
                    ? SelectableText(value.text, style: AppTextStyle.bodySmall)
                    : _CsvTable(rows: value.rows!),
              ),
            ),
          ),
          if (value.isTruncated) ...<Widget>[
            SizedBox(height: SdContentPaddingV2.listItemGap),
            Text(
              l10n.exportPreviewTruncated,
              style: AppTextStyle.bodySmall.secondary,
            ),
          ],
        ],
      ),
      // The row is still here but its file is not — the same thing the
      // actions sheet says when share or save is picked.
      AsyncError<ExportPreview>() => SdEmptyStateV2(
        icon: Icons.description_outlined,
        message: l10n.exportFileMissing,
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// The CSV as a table: header row, then one row per attack.
class _CsvTable extends StatelessWidget {
  const _CsvTable({required this.rows});

  /// Header first, then the records (see [ExportPreview.rows]).
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        context.l10n.exportPreviewEmpty,
        style: AppTextStyle.bodyMedium.secondary,
      );
    }

    // Bounded, because the horizontal scroll view above hands its child an
    // infinite width and a divider drawn into that asserts. The header
    // defines the column count; the writer never emits a wider row.
    return SizedBox(
      width: rows.first.length * ExportConstant.previewCellWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final (int index, List<String> row) in rows.indexed) ...<Widget>[
            // Between rows only: a rule above the header would land on the
            // card's own edge.
            if (index > 0) const SdDividerV2(),
            _CsvRow(cells: row, isHeader: index == 0),
          ],
        ],
      ),
    );
  }
}

class _CsvRow extends StatelessWidget {
  const _CsvRow({required this.cells, required this.isHeader});

  final List<String> cells;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: SdSpacingConstant.h8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final String cell in cells)
            SizedBox(
              width: ExportConstant.previewCellWidth,
              child: Padding(
                padding: EdgeInsets.only(right: SdSpacingConstant.w12),
                child: Text(
                  cell,
                  style: isHeader
                      ? AppTextStyle.bodySmall.w600
                      : AppTextStyle.bodySmall.secondary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
