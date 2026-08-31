import '../../features/history/domain/enums/attack_filters.dart';
import '../../features/history/domain/enums/history_period.dart';
import '../../l10n/gen/app_localizations.dart';

/// User-facing labels for the History chip row's axes.
///
/// Every axis rests on its own `all`, and every one of them says the same
/// word — the chip that is resting shows its axis name instead, which is what
/// tells thirteen chips apart (see `_FilterLabels` on the medications tab, the
/// same rule). Values that already exist elsewhere in the app keep the wording
/// they have there: an aura kind is worded once, not once per screen.
extension HistoryPeriodLabel on HistoryPeriod {
  String label(AppLocalizations l10n) => switch (this) {
    HistoryPeriod.today => l10n.historyFilterToday,
    HistoryPeriod.week => l10n.historyFilterWeek,
    HistoryPeriod.month => l10n.historyFilterMonth,
    HistoryPeriod.year => l10n.historyFilterYear,
    HistoryPeriod.all => l10n.historyFilterAll,
  };
}

extension IntensityFilterLabel on IntensityFilter {
  String label(AppLocalizations l10n) => switch (this) {
    IntensityFilter.all => l10n.historyFilterAll,
    IntensityFilter.mild => l10n.historySeverityMild,
    IntensityFilter.moderate => l10n.historySeverityModerate,
    IntensityFilter.severe => l10n.historySeveritySevere,
    IntensityFilter.extreme => l10n.historySeverityExtreme,
  };
}

extension DurationFilterLabel on DurationFilter {
  String label(AppLocalizations l10n) => switch (this) {
    DurationFilter.all => l10n.historyFilterAll,
    DurationFilter.under4h => l10n.historyFilterDurationUnder4h,
    DurationFilter.from4To72h => l10n.historyFilterDuration4To72h,
    DurationFilter.over72h => l10n.historyFilterDurationOver72h,
    DurationFilter.unrecorded => l10n.historyFilterDurationUnrecorded,
  };
}

extension AuraFilterLabel on AuraFilter {
  String label(AppLocalizations l10n) => switch (this) {
    AuraFilter.all => l10n.historyFilterAll,
    AuraFilter.visual => l10n.auraVisual,
    AuraFilter.sensory => l10n.auraSensory,
    AuraFilter.speech => l10n.auraSpeech,
    AuraFilter.motor => l10n.auraMotor,
    AuraFilter.none => l10n.auraNone,
  };
}

extension AreaFilterLabel on AreaFilter {
  String label(AppLocalizations l10n) => switch (this) {
    AreaFilter.all => l10n.historyFilterAll,
    AreaFilter.left => l10n.historyFilterAreaLeft,
    AreaFilter.right => l10n.historyFilterAreaRight,
    AreaFilter.front => l10n.historyFilterAreaFront,
    AreaFilter.back => l10n.historyFilterAreaBack,
  };
}

extension MedicationFilterLabel on MedicationFilter {
  String label(AppLocalizations l10n) => switch (this) {
    MedicationFilter.all => l10n.historyFilterAll,
    MedicationFilter.taken => l10n.historyFilterMedicationTaken,
    MedicationFilter.notTaken => l10n.historyFilterMedicationNotTaken,
  };
}

extension EffectFilterLabel on EffectFilter {
  String label(AppLocalizations l10n) => switch (this) {
    EffectFilter.all => l10n.historyFilterAll,
    EffectFilter.helped => l10n.medicationEffectHelped,
    EffectFilter.partly => l10n.medicationEffectPartly,
    EffectFilter.didNotHelp => l10n.medicationEffectDidNotHelp,
  };
}

extension ExertionFilterLabel on ExertionFilter {
  String label(AppLocalizations l10n) => switch (this) {
    ExertionFilter.all => l10n.historyFilterAll,
    ExertionFilter.none => l10n.exertionLevelNone,
    ExertionFilter.light => l10n.exertionLevelLight,
    ExertionFilter.moderate => l10n.exertionLevelModerate,
    ExertionFilter.severe => l10n.exertionLevelSevere,
  };
}

extension NotesFilterLabel on NotesFilter {
  String label(AppLocalizations l10n) => switch (this) {
    NotesFilter.all => l10n.historyFilterAll,
    NotesFilter.withNotes => l10n.historyFilterNotesWith,
    NotesFilter.withoutNotes => l10n.historyFilterNotesWithout,
  };
}

extension PressureFilterLabel on PressureFilter {
  String label(AppLocalizations l10n) => switch (this) {
    PressureFilter.all => l10n.historyFilterAll,
    PressureFilter.falling => l10n.historyFilterPressureFalling,
    PressureFilter.rising => l10n.historyFilterPressureRising,
    PressureFilter.steady => l10n.historyFilterPressureSteady,
    PressureFilter.noData => l10n.historyFilterPressureNoData,
  };
}
