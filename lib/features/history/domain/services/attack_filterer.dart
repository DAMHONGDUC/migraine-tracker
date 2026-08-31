import '../../../../core/constants/home_widget_constant.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/domain/enums/aura_type.dart';
import '../../../attacks/domain/enums/head_region.dart';
import '../enums/attack_filters.dart';
import 'attack_period_filter.dart';
import 'chart_analytics.dart';

/// Applies the History sheet's [AttackFilters] to a list of attacks. Pure Dart, so every band and every edge is a unit test rather than a screen to drive.
class AttackFilterer {
  const AttackFilterer();

  static const AttackPeriodFilterer _period = AttackPeriodFilterer();
  static const SeverityBreakdownCalculator _severity =
      SeverityBreakdownCalculator();

  /// Top of the band a migraine is defined by (ICHD-3: 4–72h); past it the attack is a different clinical question.
  static const Duration _longAttack = Duration(hours: 72);

  /// Bottom of that band.
  static const Duration _shortAttack = Duration(hours: 4);

  /// Attacks matching every axis of [filters]. Axes AND together; the values inside one axis OR, so an empty axis narrows nothing.
  List<Attack> apply(
    List<Attack> attacks,
    AttackFilters filters, {
    required DateTime now,
  }) {
    final List<Attack> byPeriod = _period.filterByPeriod(
      attacks,
      filters.period,
      now,
    );

    return byPeriod.where((Attack attack) => _matches(attack, filters)).toList();
  }

  bool _matches(Attack attack, AttackFilters filters) =>
      _matchesIntensity(attack, filters) &&
      _matchesDuration(attack, filters) &&
      _matchesAura(attack, filters) &&
      _matchesRegions(attack, filters) &&
      _matchesMedication(attack, filters) &&
      _matchesMedicationName(attack, filters) &&
      _matchesMedicationEffect(attack, filters) &&
      _matchesTexts(attack.symptoms, filters.symptoms) &&
      _matchesTexts(attack.triggers, filters.triggers) &&
      _matchesExertion(attack, filters) &&
      _matchesNotes(attack, filters) &&
      _matchesPressure(attack, filters);

  bool _matchesIntensity(Attack attack, AttackFilters filters) =>
      filters.intensity.isEmpty ||
      filters.intensity.contains(_severity.bandOf(attack.intensity));

  bool _matchesDuration(Attack attack, AttackFilters filters) =>
      filters.duration.isEmpty ||
      filters.duration.contains(durationBandOf(attack.duration));

  /// The band a duration falls in; a null one is [AttackDurationBand.unrecorded] rather than being dropped — an attack still running is a real answer.
  AttackDurationBand durationBandOf(Duration? duration) {
    if (duration == null) return AttackDurationBand.unrecorded;
    if (duration < _shortAttack) return AttackDurationBand.under4h;
    if (duration <= _longAttack) return AttackDurationBand.from4To72h;

    return AttackDurationBand.over72h;
  }

  bool _matchesAura(Attack attack, AttackFilters filters) {
    if (filters.aura.isEmpty) return true;

    final List<AuraType> aura = attack.aura ?? const <AuraType>[];
    // "No aura" covers both answers that mean it: never asked, and asked and answered none.
    if (aura.isEmpty) return filters.aura.contains(AuraFilterOption.none);

    return filters.aura.any(
      (AuraFilterOption option) =>
          option.type != null && aura.contains(option.type),
    );
  }

  bool _matchesRegions(Attack attack, AttackFilters filters) =>
      filters.regions.isEmpty ||
      attack.regions.any((HeadRegion region) => filters.regions.contains(region));

  bool _matchesMedication(Attack attack, AttackFilters filters) {
    if (filters.medication.isEmpty) return true;

    final bool taken = _medicationName(attack) != null;

    return filters.medication.contains(
      taken ? MedicationTakenFilter.taken : MedicationTakenFilter.notTaken,
    );
  }

  bool _matchesMedicationName(Attack attack, AttackFilters filters) {
    if (filters.medicationNames.isEmpty) return true;

    final String? name = _medicationName(attack);

    if (name == null) return false;

    return filters.medicationNames.any(
      (String picked) => _sameText(picked, name),
    );
  }

  bool _matchesMedicationEffect(Attack attack, AttackFilters filters) =>
      filters.medicationEffects.isEmpty ||
      filters.medicationEffects.contains(attack.medicationEffect);

  /// One rule for both free-text axes: the attack matches when it carries any of the picked words, compared the way the option list deduped them.
  bool _matchesTexts(List<String> values, Set<String> picked) =>
      picked.isEmpty ||
      values.any(
        (String value) =>
            picked.any((String choice) => _sameText(choice, value)),
      );

  bool _matchesExertion(Attack attack, AttackFilters filters) =>
      filters.exertion.isEmpty ||
      filters.exertion.contains(attack.exertionLevel);

  bool _matchesNotes(Attack attack, AttackFilters filters) {
    if (filters.notes.isEmpty) return true;

    final bool hasNotes = (attack.notes ?? '').trim().isNotEmpty;

    return filters.notes.contains(
      hasNotes ? NotesFilter.withNotes : NotesFilter.withoutNotes,
    );
  }

  bool _matchesPressure(Attack attack, AttackFilters filters) =>
      filters.pressure.isEmpty ||
      filters.pressure.contains(pressureTrendOf(attack));

  /// Which way pressure had moved over the 24h before the attack.
  ///
  /// The steady band is `HomeWidgetConstant.trendThresholdHpa` — the app
  /// already draws one line between "steady" and "a direction", and a second
  /// number here would let the home screen widget and this filter disagree
  /// about the same reading.
  PressureTrendFilter pressureTrendOf(Attack attack) {
    final double? delta = attack.weather?.pressureDelta24hHpa;

    if (delta == null) return PressureTrendFilter.noData;
    if (delta <= -HomeWidgetConstant.trendThresholdHpa) {
      return PressureTrendFilter.falling;
    }
    if (delta >= HomeWidgetConstant.trendThresholdHpa) {
      return PressureTrendFilter.rising;
    }

    return PressureTrendFilter.steady;
  }

  /// The medication on an attack, or null when nothing was taken — an empty string is the same answer as none and must not read as a name.
  String? _medicationName(Attack attack) {
    final String name = (attack.medicationName ?? '').trim();

    return name.isEmpty ? null : name;
  }

  /// How every free-text value in this feature is compared: trimmed, case-folded. The user typing "Nausea" and "nausea" meant one symptom, not two.
  static bool _sameText(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  /// The distinct values behind a free-text axis, in the spelling they were first written, most-recent attack first — what the sheet offers as chips.
  List<String> textOptions(
    List<Attack> attacks,
    List<String> Function(Attack attack) pick,
  ) {
    final Map<String, String> seen = <String, String>{};

    for (final Attack attack in attacks) {
      for (final String value in pick(attack)) {
        final String key = value.trim().toLowerCase();

        if (key.isEmpty) continue;
        seen.putIfAbsent(key, () => value.trim());
      }
    }

    return seen.values.toList();
  }
}
