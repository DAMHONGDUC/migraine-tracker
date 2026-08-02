part of 'export_screen.dart';

/// Opens the date filter and says what it is currently set to: "All dates"
/// while nothing is applied, otherwise the window itself. Sits beside the
/// history heading, the same slot History's period pill takes.
class _DateFilterPill extends ConsumerWidget {
  const _DateFilterPill();

  /// Short and locale-aware — the pill has one line to say it in.
  static DateFormat _format(AppLocalizations l10n) =>
      DateFormat.yMMMd(l10n.localeName);

  String _label(AppLocalizations l10n, ExportDateFilter filter) {
    final DateFormat format = _format(l10n);

    return switch ((filter.from, filter.to)) {
      (final DateTime from, final DateTime to) => l10n.exportFilterRange(
        format.format(from),
        format.format(to),
      ),
      (final DateTime from, null) => l10n.exportFilterSince(
        format.format(from),
      ),
      (null, final DateTime to) => l10n.exportFilterUntil(format.format(to)),
      _ => l10n.exportFilterAll,
    };
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final ExportDateFilter current = ref.read(exportFilterControllerProvider);
    final ExportDateFilter? picked = await ExportDateFilterSheet(
      initial: current,
    ).show(context);

    if (picked == null) return;
    ref.read(exportFilterControllerProvider.notifier).select(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ExportDateFilter filter = ref.watch(exportFilterControllerProvider);

    return SdFilterPillV2(
      label: _label(context.l10n, filter),
      onTap: () => _open(context, ref),
    );
  }
}
