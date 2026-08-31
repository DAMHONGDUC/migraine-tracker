part of 'export_preview_screen.dart';

/// The doctor report rendered as pages.
class _PdfBody extends ConsumerWidget {
  const _PdfBody({required this.exportId, required this.filename});

  final String exportId;
  final String filename;

  /// What the pages sit on. The package's own default is a light grey
  /// gradient — a bright panel filling the screen of an app whose users are
  /// photophobic, and the one thing here that had to change.
  ///
  /// The page itself stays white: it is paper, and a doctor report tinted to
  /// match the app would print wrong and read as a rendering fault.
  static BoxDecoration _ground(BuildContext context) =>
      BoxDecoration(color: context.sdTheme.background);

  /// The page's own edge. The package drops a hard black shadow at an offset;
  /// this is the calm version — no offset, wide and faint, the same reading a
  /// card gets (hard rule 3).
  static BoxDecoration get _page => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(SdSpacingConstant.r8),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: SdSpacingConstant.r16,
      ),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<Uint8List> bytes = ref.watch(
      exportPreviewBytesProvider(exportId),
    );

    return switch (bytes) {
      AsyncData<Uint8List>(value: final Uint8List value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Named, like the text preview: the app bar says "Preview" and the pages say nothing, so without this the screen never states which export is on it.
          // Its own gutter here, because the pages below carry theirs inside PdfPreview rather than around this column.
          Padding(
            padding: EdgeInsets.fromLTRB(
              SdContentPaddingV2.horizontal,
              SdContentPaddingV2.topGap,
              SdContentPaddingV2.horizontal,
              SdContentPaddingV2.listItemGap,
            ),
            child: _FileName(filename: filename),
          ),
          Expanded(
            child: PdfPreview(
              build: (_) async => value,
              useActions: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              allowPrinting: false,
              allowSharing: false,
              padding: SdContentPaddingV2.screen(context),
              scrollViewDecoration: _ground(context),
              pdfPreviewPageDecoration: _page,
              previewPageMargin: EdgeInsets.only(
                bottom: SdContentPaddingV2.listItemGap,
              ),
              loadingWidget: const _PageSkeleton(),
              // The package's own is red English on a grey panel; this is the same state the missing-file branch below already draws.
              onError: (BuildContext context, Object error) => SdEmptyStateV2(
                icon: AppIconConstant.document,
                message: l10n.exportFileMissing,
              ),
            ),
          ),
        ],
      ),
      AsyncError<Uint8List>() => SdEmptyStateV2(
        icon: AppIconConstant.document,
        message: l10n.exportFileMissing,
      ),
      // A page has a shape; a spinner in the middle of an empty screen does not say how much of it is about to fill.
      _ => const _PageSkeleton(),
    };
  }
}

/// The shape of the page being rendered: one tall block at the page's own
/// aspect, so nothing jumps when the render lands.
class _PageSkeleton extends StatelessWidget {
  const _PageSkeleton();

  /// A4, the format the doctor report is built at.
  static const double pageAspect = 1 / 1.414;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: SdContentPaddingV2.screen(context),
      child: Align(
        alignment: Alignment.topCenter,
        child: AspectRatio(
          aspectRatio: pageAspect,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) =>
                SdSkeletonV2(
                  height: constraints.maxHeight,
                  width: constraints.maxWidth,
                ),
          ),
        ),
      ),
    );
  }
}

/// Which export is on screen. Both previews carry it, so one widget states it
/// once — the app bar says only what kind of screen this is.
///
/// It brings no gutter: the text preview sits inside an already-padded list,
/// and doubling the inset there would put the name further in than the card
/// under it.
class _FileName extends StatelessWidget {
  const _FileName({required this.filename});

  final String filename;

  @override
  Widget build(BuildContext context) {
    return Text(
      filename,
      style: AppTextStyle.bodyMedium.secondary,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
