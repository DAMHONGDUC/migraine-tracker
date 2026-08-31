part of 'export_preview_screen.dart';

/// The doctor report rendered as pages.
class _PdfBody extends ConsumerWidget {
  const _PdfBody({required this.exportId});

  final String exportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<Uint8List> bytes = ref.watch(
      exportPreviewBytesProvider(exportId),
    );

    return switch (bytes) {
      AsyncData<Uint8List>(value: final Uint8List value) => PdfPreview(
        build: (_) async => value,
        useActions: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: false,
        allowSharing: false,
        padding: SdContentPaddingV2.screen(context),
        loadingWidget: const _PageSkeleton(),
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
