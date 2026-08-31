import 'package:meta/meta.dart';

import '../../../attacks/domain/enums/aura_type.dart';
import '../../../attacks/domain/enums/exertion_level.dart';
import '../../../attacks/domain/enums/head_location.dart';
import '../../../attacks/domain/enums/head_region.dart';
import '../../../attacks/domain/enums/medication_effect.dart';
import '../services/chart_analytics.dart';
import 'history_period.dart';

/// Pain intensity, in the four bands the severity donut already splits on.
enum IntensityFilter {
  all,
  mild,
  moderate,
  severe,
  extreme;

  /// The band this stands for, or null for [all]. The thresholds stay in [SeverityBreakdownCalculator]; this only names which band.
  SeverityBand? get band => switch (this) {
    IntensityFilter.all => null,
    IntensityFilter.mild => SeverityBand.mild,
    IntensityFilter.moderate => SeverityBand.moderate,
    IntensityFilter.severe => SeverityBand.severe,
    IntensityFilter.extreme => SeverityBand.extreme,
  };
}

/// How long the attack lasted, in the bands the diagnosis is written in: under 4h is short of what defines a migraine, 4–72h is that band, past it is.
enum DurationFilter { all, under4h, from4To72h, over72h, unrecorded }

/// The four aura kinds, plus the answer "no aura" — which people filter for as much as the kinds themselves.
enum AuraFilter {
  all,
  visual,
  sensory,
  speech,
  motor,
  none;

  /// The kind this stands for; null for [all] and for [none], which the filterer reads as "nothing reported".
  AuraType? get type => switch (this) {
    AuraFilter.visual => AuraType.visual,
    AuraFilter.sensory => AuraType.sensory,
    AuraFilter.speech => AuraType.speech,
    AuraFilter.motor => AuraType.motor,
    AuraFilter.all || AuraFilter.none => null,
  };
}

/// Which side or face of the head hurt.
///
/// **Coarse on purpose, not the fifteen `HeadRegion`s.** A single-choice sheet
/// of fifteen areas is a list to scroll rather than a filter to read, and the
/// question people actually ask their record is "is it always the left side?".
enum AreaFilter {
  all,
  left,
  right,
  front,
  back;

  /// The regions this covers, borrowed from [HeadLocation] so the two lists cannot drift apart.
  List<HeadRegion> get regions => switch (this) {
    AreaFilter.all => const <HeadRegion>[],
    AreaFilter.left => HeadLocation.left.regions,
    AreaFilter.right => HeadLocation.right.regions,
    AreaFilter.front => HeadLocation.front.regions,
    AreaFilter.back => HeadLocation.back.regions,
  };
}

/// Whether anything was taken for the attack.
enum MedicationFilter { all, taken, notTaken }

/// Whether the medication helped, once that was answered.
enum EffectFilter {
  all,
  helped,
  partly,
  didNotHelp;

  MedicationEffect? get effect => switch (this) {
    EffectFilter.all => null,
    EffectFilter.helped => MedicationEffect.helped,
    EffectFilter.partly => MedicationEffect.partly,
    EffectFilter.didNotHelp => MedicationEffect.didNotHelp,
  };
}

/// Self-reported exertion around the attack.
enum ExertionFilter {
  all,
  none,
  light,
  moderate,
  severe;

  ExertionLevel? get level => switch (this) {
    ExertionFilter.all => null,
    ExertionFilter.none => ExertionLevel.none,
    ExertionFilter.light => ExertionLevel.light,
    ExertionFilter.moderate => ExertionLevel.moderate,
    ExertionFilter.severe => ExertionLevel.severe,
  };
}

/// Whether the attack carries a written note.
enum NotesFilter { all, withNotes, withoutNotes }

/// Which way pressure had moved over the 24h before the attack. [noData] is its own answer: an attack logged offline that was never backfilled.
enum PressureFilter { all, falling, rising, steady, noData }

/// Every axis the History list can be narrowed by, in one value.
///
/// **One axis per chip, each a single choice with its own "All"** — the same
/// shape as the medications tab (owner's call). Nothing here is a set: a chip
/// says which one value is being asked for, and the chip row is read at a
/// glance rather than opened.
///
/// The three free-text axes hold a plain [String] and rest at [anyText] rather
/// than null, so `copyWith` can tell "not passed" from "cleared" without a
/// sentinel.
@immutable
class AttackFilters {
  const AttackFilters({
    this.period = HistoryPeriod.all,
    this.intensity = IntensityFilter.all,
    this.duration = DurationFilter.all,
    this.aura = AuraFilter.all,
    this.area = AreaFilter.all,
    this.medication = MedicationFilter.all,
    this.medicationName = anyText,
    this.effect = EffectFilter.all,
    this.symptom = anyText,
    this.trigger = anyText,
    this.exertion = ExertionFilter.all,
    this.notes = NotesFilter.all,
    this.pressure = PressureFilter.all,
  });

  /// What a free-text axis rests at: nothing picked, so nothing filtered.
  static const String anyText = '';

  final HistoryPeriod period;
  final IntensityFilter intensity;
  final DurationFilter duration;
  final AuraFilter aura;
  final AreaFilter area;
  final MedicationFilter medication;

  /// A medication name exactly as the user's own records spell it; matched case-insensitively, because a picker and a typed name can disagree on case.
  final String medicationName;

  final EffectFilter effect;

  /// One free-text symptom, offered from what the user has actually written.
  final String symptom;

  /// One free-text trigger, offered the same way.
  final String trigger;

  final ExertionFilter exertion;
  final NotesFilter notes;
  final PressureFilter pressure;

  /// How many axes are narrowing the list — what the summary line above it counts, and what a chip strip alone cannot say once it scrolls sideways.
  int get activeCount => <bool>[
    period != HistoryPeriod.all,
    intensity != IntensityFilter.all,
    duration != DurationFilter.all,
    aura != AuraFilter.all,
    area != AreaFilter.all,
    medication != MedicationFilter.all,
    medicationName != anyText,
    effect != EffectFilter.all,
    symptom != anyText,
    trigger != anyText,
    exertion != ExertionFilter.all,
    notes != NotesFilter.all,
    pressure != PressureFilter.all,
  ].where((bool on) => on).length;

  bool get isDefault => activeCount == 0;

  AttackFilters copyWith({
    HistoryPeriod? period,
    IntensityFilter? intensity,
    DurationFilter? duration,
    AuraFilter? aura,
    AreaFilter? area,
    MedicationFilter? medication,
    String? medicationName,
    EffectFilter? effect,
    String? symptom,
    String? trigger,
    ExertionFilter? exertion,
    NotesFilter? notes,
    PressureFilter? pressure,
  }) => AttackFilters(
    period: period ?? this.period,
    intensity: intensity ?? this.intensity,
    duration: duration ?? this.duration,
    aura: aura ?? this.aura,
    area: area ?? this.area,
    medication: medication ?? this.medication,
    medicationName: medicationName ?? this.medicationName,
    effect: effect ?? this.effect,
    symptom: symptom ?? this.symptom,
    trigger: trigger ?? this.trigger,
    exertion: exertion ?? this.exertion,
    notes: notes ?? this.notes,
    pressure: pressure ?? this.pressure,
  );

  // Value equality is what stops the providers re-filtering the list on a value that was rebuilt the same.
  @override
  bool operator ==(Object other) =>
      other is AttackFilters &&
      other.period == period &&
      other.intensity == intensity &&
      other.duration == duration &&
      other.aura == aura &&
      other.area == area &&
      other.medication == medication &&
      other.medicationName == medicationName &&
      other.effect == effect &&
      other.symptom == symptom &&
      other.trigger == trigger &&
      other.exertion == exertion &&
      other.notes == notes &&
      other.pressure == pressure;

  @override
  int get hashCode => Object.hash(
    period,
    intensity,
    duration,
    aura,
    area,
    medication,
    medicationName,
    effect,
    symptom,
    trigger,
    exertion,
    notes,
    pressure,
  );
}
