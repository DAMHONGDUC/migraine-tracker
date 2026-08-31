part of 'export_preview_screen.dart';

/// A JSON export, read as its own text.
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
              // Its own horizontal scroll, so long lines run off the card rather than off the page.
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  value.text,
                  style: AppTextStyle.bodySmall,
                ),
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
      // The row is still here but its file is not — the same thing the actions sheet says when share or save is picked.
      AsyncError<ExportPreview>() => SdEmptyStateV2(
        icon: AppIconConstant.document,
        message: l10n.exportFileMissing,
      ),
      // The shape is known — a page of lines — so it is drawn rather than spun for.
      _ => const _TextSkeleton(),
    };
  }
}

/// A page of lines, in place of the page that has not been read off disk yet.
class _TextSkeleton extends StatelessWidget {
  const _TextSkeleton();

  /// Enough to fill the shortest screen this generation ships on.
  static const int lines = 14;

  /// Ragged like real text, and repeated rather than random so the placeholder
  /// does not redraw differently on every rebuild.
  static const List<double> fractions = <double>[1, 0.92, 0.68, 0.85];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: SdContentPaddingV2.screen(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < lines; i++) ...<Widget>[
            if (i > 0) SizedBox(height: SdSkeletonV2.lineGap),
            SdSkeletonV2.line(fraction: fractions[i % fractions.length]),
          ],
        ],
      ),
    );
  }
}
