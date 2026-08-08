part of 'export_preview_screen.dart';

/// A JSON or CSV export, read as text. Selectable, so a line can be copied
/// out without sharing the whole file.
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
              child: SelectableText(
                value.text,
                style: AppTextStyle.bodySmall,
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
