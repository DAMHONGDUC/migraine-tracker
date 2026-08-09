part of 'export_preview_screen.dart';

/// A JSON export, read as its own text.
///
/// It does not wrap: indented JSON carries its meaning in the line breaks the
/// file already has, so the card scrolls sideways instead of reflowing them
/// away.
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
              // Its own horizontal scroll, so long lines run off the card
              // rather than off the page.
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
