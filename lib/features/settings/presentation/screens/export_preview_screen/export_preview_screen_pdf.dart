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
        loadingWidget: const CircularProgressIndicator(),
      ),
      AsyncError<Uint8List>() => SdEmptyStateV2(
        icon: AppIconConstant.document,
        message: l10n.exportFileMissing,
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
