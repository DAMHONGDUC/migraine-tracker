part of 'medications_screen.dart';

/// The tab's three axes in one sheet, labelled by the same [_FilterLabels] as the chips. Pops the draft on Apply; null when closed without it.
class _MedicationFilterSheet extends StatefulWidget {
  const _MedicationFilterSheet({required this.initial});

  /// The filters on now, so the sheet opens where the strip is.
  final MedicationFilters initial;

  @override
  State<_MedicationFilterSheet> createState() => _MedicationFilterSheetState();
}

class _MedicationFilterSheetState extends State<_MedicationFilterSheet> {
  late MedicationFilters _draft = widget.initial;

  void _update(MedicationFilters next) => setState(() => _draft = next);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return AllFiltersSheet(
      sections: <Widget>[
        SdFilterSectionV2<MedicationDateFilter>(
          title: l10n.medicationsFilterDateTitle,
          // "All" is last in the enum; it leads here, as every axis' resting value does.
          options: const <MedicationDateFilter>[
            MedicationDateFilter.all,
            MedicationDateFilter.today,
            MedicationDateFilter.week,
            MedicationDateFilter.month,
            MedicationDateFilter.year,
          ],
          selected: _draft.date,
          labelBuilder: (MedicationDateFilter value) =>
              _FilterLabels.date(context, value),
          onSelected: (MedicationDateFilter value) =>
              _update(_draft.copyWith(date: value)),
        ),
        SdFilterSectionV2<MedicationReminderFilter>(
          title: l10n.medicationsFilterReminderTitle,
          options: MedicationReminderFilter.values,
          selected: _draft.reminder,
          labelBuilder: (MedicationReminderFilter value) =>
              _FilterLabels.reminder(context, value),
          onSelected: (MedicationReminderFilter value) =>
              _update(_draft.copyWith(reminder: value)),
        ),
        SdFilterSectionV2<MedicationUsageFilter>(
          title: l10n.medicationsFilterUsageTitle,
          options: MedicationUsageFilter.values,
          selected: _draft.usage,
          labelBuilder: (MedicationUsageFilter value) =>
              _FilterLabels.usage(context, value),
          onSelected: (MedicationUsageFilter value) =>
              _update(_draft.copyWith(usage: value)),
        ),
      ],
      onApply: () => Navigator.of(context).pop(_draft),
      onClear: _draft.isDefault
          ? null
          : () => _update(const MedicationFilters()),
    );
  }
}

/// Sheets expose their opener as `.show(context)` (CLAUDE.md § Code style).
extension _MedicationFilterSheetExt on _MedicationFilterSheet {
  Future<MedicationFilters?> show(BuildContext context) =>
      showSdBottomSheetV2<MedicationFilters>(
        context,
        isScrollControlled: true,
        builder: (_) => this,
      );
}
