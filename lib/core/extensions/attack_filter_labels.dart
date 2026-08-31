import '../../features/history/domain/enums/attack_filters.dart';
import '../../features/history/domain/enums/history_period.dart';
import '../../l10n/gen/app_localizations.dart';
import 'aura_label.dart';

/// User-facing labels for the History filter sheet's own enums. The axes that filter on an existing enum — aura kind, head region, medication effect,.
extension HistoryPeriodLabel on HistoryPeriod {
  String label(AppLocalizations l10n) => switch (this) {
    HistoryPeriod.today => l10n.historyFilterToday,
    HistoryPeriod.week => l10n.historyFilterWeek,
    HistoryPeriod.month => l10n.historyFilterMonth,
    HistoryPeriod.year => l10n.historyFilterYear,
    HistoryPeriod.all => l10n.historyFilterAll,
  };
}

extension AttackDurationBandLabel on AttackDurationBand {
  String label(AppLocalizations l10n) => switch (this) {
    AttackDurationBand.under4h => l10n.historyFilterDurationUnder4h,
    AttackDurationBand.from4To72h => l10n.historyFilterDuration4To72h,
    AttackDurationBand.over72h => l10n.historyFilterDurationOver72h,
    AttackDurationBand.unrecorded => l10n.historyFilterDurationUnrecorded,
  };
}

extension AuraFilterOptionLabel on AuraFilterOption {
  /// The four kinds keep the words the aura picker uses; [AuraFilterOption.none] takes that sheet's own "No aura", so the filter and the record agree.
  String label(AppLocalizations l10n) =>
      type?.label(l10n) ?? l10n.auraNone;
}

extension MedicationTakenFilterLabel on MedicationTakenFilter {
  String label(AppLocalizations l10n) => switch (this) {
    MedicationTakenFilter.taken => l10n.historyFilterMedicationTaken,
    MedicationTakenFilter.notTaken => l10n.historyFilterMedicationNotTaken,
  };
}

extension NotesFilterLabel on NotesFilter {
  String label(AppLocalizations l10n) => switch (this) {
    NotesFilter.withNotes => l10n.historyFilterNotesWith,
    NotesFilter.withoutNotes => l10n.historyFilterNotesWithout,
  };
}

extension PressureTrendFilterLabel on PressureTrendFilter {
  String label(AppLocalizations l10n) => switch (this) {
    PressureTrendFilter.falling => l10n.historyFilterPressureFalling,
    PressureTrendFilter.rising => l10n.historyFilterPressureRising,
    PressureTrendFilter.steady => l10n.historyFilterPressureSteady,
    PressureTrendFilter.noData => l10n.historyFilterPressureNoData,
  };
}
