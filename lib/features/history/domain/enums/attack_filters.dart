import 'package:meta/meta.dart';

import '../../../attacks/domain/enums/aura_type.dart';
import '../../../attacks/domain/enums/exertion_level.dart';
import '../../../attacks/domain/enums/head_region.dart';
import '../../../attacks/domain/enums/medication_effect.dart';
import '../services/chart_analytics.dart';
import 'history_period.dart';

/// How long the attack lasted, in the bands the diagnosis itself is written in: under 4h is short of what defines a migraine, 4–72h is that band, past it.
enum AttackDurationBand { under4h, from4To72h, over72h, unrecorded }

/// One row of the aura section — the four kinds, plus the answer "no aura", which is a filter people want as much as the kinds themselves.
enum AuraFilterOption {
  visual,
  sensory,
  speech,
  motor,
  none;

  /// The kind this option stands for, or null for [none].
  AuraType? get type => switch (this) {
    AuraFilterOption.visual => AuraType.visual,
    AuraFilterOption.sensory => AuraType.sensory,
    AuraFilterOption.speech => AuraType.speech,
    AuraFilterOption.motor => AuraType.motor,
    AuraFilterOption.none => null,
  };
}

/// Whether anything was taken for the attack.
enum MedicationTakenFilter { taken, notTaken }

/// Whether the attack carries a written note.
enum NotesFilter { withNotes, withoutNotes }

/// Which way pressure had moved over the 24h before the attack. [noData] is its own answer: an attack logged offline that was never backfilled.
enum PressureTrendFilter { falling, rising, steady, noData }

/// Every axis the History list can be narrowed by, in one value.
///
/// **Each axis is a set, empty means "not filtered", and the sets combine OR
/// inside an axis and AND across axes.** One shape for twelve axes is what
/// lets the sheet draw them all from one widget and the filterer read them in
/// one pass — the alternative was a tri-state enum per axis, which reads
/// differently in every one of them.
///
/// [period] is the exception and stays a single choice: a window is one
/// window, and "today OR this year" is just "this year".
@immutable
class AttackFilters {
  const AttackFilters({
    this.period = HistoryPeriod.all,
    this.intensity = const <SeverityBand>{},
    this.duration = const <AttackDurationBand>{},
    this.aura = const <AuraFilterOption>{},
    this.regions = const <HeadRegion>{},
    this.medication = const <MedicationTakenFilter>{},
    this.medicationNames = const <String>{},
    this.medicationEffects = const <MedicationEffect>{},
    this.symptoms = const <String>{},
    this.triggers = const <String>{},
    this.exertion = const <ExertionLevel>{},
    this.notes = const <NotesFilter>{},
    this.pressure = const <PressureTrendFilter>{},
  });

  final HistoryPeriod period;
  final Set<SeverityBand> intensity;
  final Set<AttackDurationBand> duration;
  final Set<AuraFilterOption> aura;
  final Set<HeadRegion> regions;
  final Set<MedicationTakenFilter> medication;

  /// Medication names exactly as the user's own records spell them; matched case-insensitively, because the picker and a typed name can disagree on case.
  final Set<String> medicationNames;

  final Set<MedicationEffect> medicationEffects;

  /// Free-text symptoms, offered from what the user has actually written.
  final Set<String> symptoms;

  /// Free-text triggers, offered the same way.
  final Set<String> triggers;

  final Set<ExertionLevel> exertion;
  final Set<NotesFilter> notes;
  final Set<PressureTrendFilter> pressure;

  /// How many axes are narrowing the list — what the pill counts, so the user can see there IS a filter on without opening the sheet.
  int get activeCount {
    int count = period == HistoryPeriod.all ? 0 : 1;

    for (final Set<Object> axis in _axes) {
      if (axis.isNotEmpty) count++;
    }

    return count;
  }

  bool get isDefault => activeCount == 0;

  List<Set<Object>> get _axes => <Set<Object>>[
    intensity,
    duration,
    aura,
    regions,
    medication,
    medicationNames,
    medicationEffects,
    symptoms,
    triggers,
    exertion,
    notes,
    pressure,
  ];

  AttackFilters copyWith({
    HistoryPeriod? period,
    Set<SeverityBand>? intensity,
    Set<AttackDurationBand>? duration,
    Set<AuraFilterOption>? aura,
    Set<HeadRegion>? regions,
    Set<MedicationTakenFilter>? medication,
    Set<String>? medicationNames,
    Set<MedicationEffect>? medicationEffects,
    Set<String>? symptoms,
    Set<String>? triggers,
    Set<ExertionLevel>? exertion,
    Set<NotesFilter>? notes,
    Set<PressureTrendFilter>? pressure,
  }) => AttackFilters(
    period: period ?? this.period,
    intensity: intensity ?? this.intensity,
    duration: duration ?? this.duration,
    aura: aura ?? this.aura,
    regions: regions ?? this.regions,
    medication: medication ?? this.medication,
    medicationNames: medicationNames ?? this.medicationNames,
    medicationEffects: medicationEffects ?? this.medicationEffects,
    symptoms: symptoms ?? this.symptoms,
    triggers: triggers ?? this.triggers,
    exertion: exertion ?? this.exertion,
    notes: notes ?? this.notes,
    pressure: pressure ?? this.pressure,
  );

  /// Same members, whatever order they were added in. Written out rather than taken from `package:collection` — `domain/` is pure Dart and owns no packages.
  static bool _sameSet(Set<Object> a, Set<Object> b) =>
      a.length == b.length && a.containsAll(b);

  // Value equality is what stops the providers rebuilding the list on a set that was rebuilt with the same members.
  @override
  bool operator ==(Object other) {
    if (other is! AttackFilters) return false;
    if (other.period != period) return false;

    final List<Set<Object>> mine = _axes;
    final List<Set<Object>> theirs = other._axes;

    for (int i = 0; i < mine.length; i++) {
      if (!_sameSet(mine[i], theirs[i])) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    period,
    Object.hashAllUnordered(intensity),
    Object.hashAllUnordered(duration),
    Object.hashAllUnordered(aura),
    Object.hashAllUnordered(regions),
    Object.hashAllUnordered(medication),
    Object.hashAllUnordered(medicationNames),
    Object.hashAllUnordered(medicationEffects),
    Object.hashAllUnordered(symptoms),
    Object.hashAllUnordered(triggers),
    Object.hashAllUnordered(exertion),
    Object.hashAllUnordered(notes),
    Object.hashAllUnordered(pressure),
  );
}
