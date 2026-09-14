import '../../../../core/constants/home_widget_constant.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/domain/enums/aura_type.dart';
import '../../../attacks/domain/enums/exertion_level.dart';
import '../../../attacks/domain/enums/head_region.dart';
import '../../../attacks/domain/enums/medication_effect.dart';
import '../enums/attack_filters.dart';
import 'attack_period_filter.dart';
import 'chart_analytics.dart';

/// Applies the History chip row's [AttackFilters] to a list of attacks. Pure Dart, so every band and every edge is a unit test rather than a screen to drive.
class AttackFilterer {
  const AttackFilterer();

  static const AttackPeriodFilterer _period = AttackPeriodFilterer();
  static const SeverityBreakdownCalculator _severity =
      SeverityBreakdownCalculator();

  /// Top of the band a migraine is defined by (ICHD-3: 4–72h); past it the attack is a different clinical question.
  static const Duration _longAttack = Duration(hours: 72);

  /// Bottom of that band.
  static const Duration _shortAttack = Duration(hours: 4);

  /// Attacks matching every axis of [filters] — the axes AND together, and an axis resting on its "all" narrows nothing.
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

    return byPeriod
        .where((Attack attack) => _matches(attack, filters))
        .toList();
  }

  bool _matches(Attack attack, AttackFilters filters) =>
      _matchesIntensity(attack, filters) &&
      _matchesDuration(attack, filters) &&
      _matchesAura(attack, filters) &&
      _matchesArea(attack, filters) &&
      _matchesMedication(attack, filters) &&
      _matchesMedicationName(attack, filters) &&
      _matchesEffect(attack, filters) &&
      _matchesText(attack.symptoms, filters.symptom) &&
      _matchesText(attack.triggers, filters.trigger) &&
      _matchesExertion(attack, filters) &&
      _matchesNotes(attack, filters) &&
      _matchesPressure(attack, filters);

  bool _matchesIntensity(Attack attack, AttackFilters filters) {
    final SeverityBand? band = filters.intensity.band;

    return band == null || _severity.bandOf(attack.intensity) == band;
  }

  bool _matchesDuration(Attack attack, AttackFilters filters) =>
      filters.duration == DurationFilter.all ||
      durationBandOf(attack.duration) == filters.duration;

  /// The band a duration falls in; a null one is [DurationFilter.unrecorded] rather than being dropped — an attack still running is a real answer.
  DurationFilter durationBandOf(Duration? duration) {
    if (duration == null) return DurationFilter.unrecorded;
    if (duration < _shortAttack) return DurationFilter.under4h;
    if (duration <= _longAttack) return DurationFilter.from4To72h;

    return DurationFilter.over72h;
  }

  bool _matchesAura(Attack attack, AttackFilters filters) {
    if (filters.aura == AuraFilter.all) return true;

    final List<AuraType> aura = attack.aura ?? const <AuraType>[];

    // "No aura" covers both answers that mean it: never asked, and asked and answered none.
    if (filters.aura == AuraFilter.none) return aura.isEmpty;

    return aura.contains(filters.aura.type);
  }

  bool _matchesArea(Attack attack, AttackFilters filters) {
    if (filters.area == AreaFilter.all) return true;

    final List<HeadRegion> wanted = filters.area.regions;

    return attack.regions.any(wanted.contains);
  }

  bool _matchesMedication(Attack attack, AttackFilters filters) =>
      switch (filters.medication) {
        MedicationFilter.all => true,
        MedicationFilter.taken => _medicationName(attack) != null,
        MedicationFilter.notTaken => _medicationName(attack) == null,
      };

  bool _matchesMedicationName(Attack attack, AttackFilters filters) {
    if (filters.medicationName == AttackFilters.anyText) return true;

    final String? name = _medicationName(attack);

    return name != null && _sameText(name, filters.medicationName);
  }

  bool _matchesEffect(Attack attack, AttackFilters filters) {
    final MedicationEffect? effect = filters.effect.effect;

    return effect == null || attack.medicationEffect == effect;
  }

  /// One rule for both free-text axes: the attack matches when it carries the picked word, compared the way the option list deduped it.
  bool _matchesText(List<String> values, String picked) =>
      picked == AttackFilters.anyText ||
      values.any((String value) => _sameText(value, picked));

  bool _matchesExertion(Attack attack, AttackFilters filters) {
    final ExertionLevel? level = filters.exertion.level;

    return level == null || attack.exertionLevel == level;
  }

  bool _matchesNotes(Attack attack, AttackFilters filters) {
    if (filters.notes == NotesFilter.all) return true;

    final bool hasNotes = (attack.notes ?? '').trim().isNotEmpty;

    return filters.notes ==
        (hasNotes ? NotesFilter.withNotes : NotesFilter.withoutNotes);
  }

  bool _matchesPressure(Attack attack, AttackFilters filters) =>
      filters.pressure == PressureFilter.all ||
      pressureTrendOf(attack) == filters.pressure;

  /// Which way pressure had moved over the 24h before the attack.
  ///
  /// The steady band is `HomeWidgetConstant.trendThresholdHpa` — the app
  /// already draws one line between "steady" and "a direction", and a second
  /// number here would let the home screen widget and this filter disagree
  /// about the same reading.
  PressureFilter pressureTrendOf(Attack attack) {
    final double? delta = attack.weather?.pressureDelta24hHpa;

    if (delta == null) return PressureFilter.noData;
    if (delta <= -HomeWidgetConstant.trendThresholdHpa) {
      return PressureFilter.falling;
    }
    if (delta >= HomeWidgetConstant.trendThresholdHpa) {
      return PressureFilter.rising;
    }

    return PressureFilter.steady;
  }

  /// The medication on an attack, or null when nothing was taken — an empty string is the same answer as none and must not read as a name.
  String? _medicationName(Attack attack) {
    final String name = (attack.medicationName ?? '').trim();

    return name.isEmpty ? null : name;
  }

  /// How every free-text value in this feature is compared: trimmed, case-folded. The user typing "Nausea" and "nausea" meant one symptom, not two.
  static bool _sameText(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  /// The distinct values behind a free-text axis, in the spelling they were first written, most-recent attack first — what the chip's sheet offers.
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
