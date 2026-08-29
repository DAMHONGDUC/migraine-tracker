import '../../../attacks/domain/entities/attack.dart';
import '../../../health/domain/entities/sleep_night.dart';
import '../entities/sleep_correlation_result.dart';

/// Sleep correlation: did the user sleep less on the nights their attacks followed?
class SleepCorrelationEngine {
  const SleepCorrelationEngine({
    this.minNights = defaultMinNights,
    this.minNightsPerGroup = defaultMinNightsPerGroup,
    this.variationEpsilon = defaultVariationEpsilon,
  }) : assert(minNights > 0, 'minNights must be positive'),
       assert(minNightsPerGroup > 0, 'minNightsPerGroup must be positive');

  /// Same floor as the pressure correlation: below this many nights the comparison is noise.
  static const int defaultMinNights = 15;

  /// And each side of the comparison needs its own minimum — 14 quiet nights and one attack night is one anecdote, not an average.
  static const int defaultMinNightsPerGroup = 3;

  /// Averages closer than this are the same night's sleep as far as a person is concerned.
  static const Duration defaultVariationEpsilon = Duration(minutes: 15);

  /// How far back to read sleep for the analysis.
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

    // An empty side is the one thing no result can be built from: there is no comparison, not merely a thin one.
    if (attackNights.isEmpty || restNights.isEmpty) {
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
    final bool settled =
        nights.length >= minNights &&
        attackNights.length >= minNightsPerGroup &&
        restNights.length >= minNightsPerGroup;

    // "The same night's sleep" is only a verdict at a real sample; below it the card shows the two averages, which need no spread to be true.
    if (settled && (restAverage - attackAverage).abs() < variationEpsilon) {
      return SleepNoVariation(nightsAnalyzed: nights.length);
    }

    return SleepInsight(
      attackNightAverage: attackAverage,
      restNightAverage: restAverage,
      attackNights: attackNights.length,
      restNights: restNights.length,
      requiredNights: minNights,
      requiredPerGroup: minNightsPerGroup,
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
