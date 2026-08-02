import '../../../attacks/domain/entities/attack.dart';
import '../../../health/domain/entities/sleep_night.dart';
import '../entities/sleep_correlation_result.dart';

/// Sleep correlation: did the user sleep less on the nights their attacks
/// followed?
///
/// Pure Dart and deterministic. It joins on the *local* calendar date, which
/// is the only join that matches how a person experiences a night: a night is
/// labelled by the morning it ends ([SleepNight.date]), and an attack belongs
/// to the local day it started. `Attack.startedAt` is stored in UTC, so the
/// engine converts back before taking the date — comparing a UTC date to a
/// local one silently shifts whole nights into the wrong bucket for anyone
/// east of Greenwich.
class SleepCorrelationEngine {
  const SleepCorrelationEngine({
    this.minNights = defaultMinNights,
    this.minNightsPerGroup = defaultMinNightsPerGroup,
    this.variationEpsilon = defaultVariationEpsilon,
  }) : assert(minNights > 0, 'minNights must be positive'),
       assert(minNightsPerGroup > 0, 'minNightsPerGroup must be positive');

  /// Same floor as the pressure correlation: below this many nights the
  /// comparison is noise.
  static const int defaultMinNights = 15;

  /// And each side of the comparison needs its own minimum — 14 quiet nights
  /// and one attack night is one anecdote, not an average.
  static const int defaultMinNightsPerGroup = 3;

  /// Averages closer than this are the same night's sleep as far as a person
  /// is concerned.
  static const Duration defaultVariationEpsilon = Duration(minutes: 15);

  /// How far back to read sleep for the analysis. Bounded on purpose:
  /// HealthKit hands over every night ever recorded if asked, and the app has
  /// no business reading years it will not use.
  static const int defaultLookbackDays = 180;

  final int minNights;
  final int minNightsPerGroup;
  final Duration variationEpsilon;

  SleepCorrelationResult analyze({
    required List<Attack> attacks,
    required List<SleepNight> nights,
  }) {
    final Set<DateTime> attackDates = <DateTime>{
      for (final Attack attack in attacks) _localDate(attack.startedAt),
    };
    final List<SleepNight> attackNights = <SleepNight>[];
    final List<SleepNight> restNights = <SleepNight>[];

    for (final SleepNight night in nights) {
      final DateTime date = _dateOnly(night.date);

      (attackDates.contains(date) ? attackNights : restNights).add(night);
    }

    if (nights.length < minNights ||
        attackNights.length < minNightsPerGroup ||
        restNights.length < minNightsPerGroup) {
      return SleepInsufficientData(
        nightsWithSleep: nights.length,
        requiredNights: minNights,
        attackNights: attackNights.length,
        restNights: restNights.length,
        requiredPerGroup: minNightsPerGroup,
      );
    }

    final Duration attackAverage = _average(attackNights);
    final Duration restAverage = _average(restNights);

    if ((restAverage - attackAverage).abs() < variationEpsilon) {
      return SleepNoVariation(nightsAnalyzed: nights.length);
    }

    return SleepInsight(
      attackNightAverage: attackAverage,
      restNightAverage: restAverage,
      attackNights: attackNights.length,
      restNights: restNights.length,
    );
  }

  /// Mean of [nights]; the caller has already ruled out an empty list.
  Duration _average(List<SleepNight> nights) {
    int minutes = 0;

    for (final SleepNight night in nights) {
      minutes += night.duration.inMinutes;
    }

    return Duration(minutes: minutes ~/ nights.length);
  }

  DateTime _localDate(DateTime instant) => _dateOnly(instant.toLocal());

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
