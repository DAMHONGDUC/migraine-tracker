import '../../../attacks/domain/entities/attack.dart';
import '../../../weather/domain/entities/daily_pressure.dart';
import '../entities/correlation_result.dart';

/// Correlation engine v1: what share of attacks happened during a rapid
/// barometric pressure drop?
///
/// Pure Dart, deterministic, timezone-agnostic: it only looks at the
/// pressure deltas already attached to each attack's weather snapshot, never
/// at wall-clock time.
///
/// It analyses from the first attack with weather and reports how far along
/// the sample is, rather than withholding a result — the two thresholds below
/// grade the answer, they do not gate it.
class CorrelationEngine {
  const CorrelationEngine({
    this.minAttacks = defaultMinAttacks,
    this.minAttacksForShare = defaultMinAttacksForShare,
    this.dropThresholdHpa = defaultDropThresholdHpa,
    this.minDaysPerSide = defaultMinDaysPerSide,
  }) : assert(minAttacks > 0, 'minAttacks must be positive'),
       assert(minAttacksForShare > 0, 'minAttacksForShare must be positive'),
       assert(dropThresholdHpa > 0, 'dropThresholdHpa must be positive'),
       assert(minDaysPerSide > 0, 'minDaysPerSide must be positive');

  /// Where the share settles. The normal approximation behind any confidence
  /// claim needs ~5 attacks on each side of the threshold, which lands here
  /// when roughly a third of attacks fall during drops.
  static const int defaultMinAttacks = 15;

  /// Below this the result asks for counts instead of a percentage: at 1–4
  /// attacks a share can only be 0/25/33/50/100, all of which read as claims.
  static const int defaultMinAttacksForShare = 5;

  /// A 24h pressure drop of at least this many hPa counts as "rapid".
  static const double defaultDropThresholdHpa = 5.0;

  /// Days needed on EACH side before the baseline comparison is stated. Five
  /// for the same reason [defaultMinAttacks] is 15: below it a single day
  /// moves the rate by 20 points or more, and the card would swing between
  /// "twice as likely" and "no difference" on one night's weather.
  static const int defaultMinDaysPerSide = 5;

  /// Two snapshots whose deltas differ less than this are "the same weather".
  static const double _variationEpsilonHpa = 0.5;

  final int minAttacks;
  final int minAttacksForShare;
  final double dropThresholdHpa;
  final int minDaysPerSide;

  /// [days] is the per-day pressure history — the denominator. Empty is the
  /// normal state for a user whose history predates it being recorded, and
  /// the result then carries no baseline rather than a made-up one.
  CorrelationResult analyze(
    List<Attack> attacks, {
    List<DailyPressure> days = const <DailyPressure>[],
  }) {
    final List<Attack> withWeather = attacks
        .where((a) => a.weather != null)
        .toList();

    if (withWeather.isEmpty) {
      return CorrelationInsufficientData(
        attacksAnalyzed: 0,
        requiredAttacks: minAttacks,
      );
    }

    final List<double> deltas = withWeather
        .map((a) => a.weather!.pressureDelta24hHpa)
        .toList();
    final double min = deltas.reduce((a, b) => a < b ? a : b);
    final double max = deltas.reduce((a, b) => a > b ? a : b);
    final int duringDrop = deltas.where((d) => d <= -dropThresholdHpa).length;

    // Flat weather only means something with several deltas to compare; below
    // that the card shows counts, which need no spread to be true.
    if (withWeather.length >= minAttacksForShare &&
        max - min < _variationEpsilonHpa) {
      return CorrelationNoVariation(
        attacksAnalyzed: withWeather.length,
        requiredAttacks: minAttacks,
      );
    }

    return CorrelationInsight(
      attacksAnalyzed: withWeather.length,
      requiredAttacks: minAttacks,
      attacksDuringPressureDrop: duringDrop,
      dropThresholdHpa: dropThresholdHpa,
      minAttacksForShare: minAttacksForShare,
      baseline: _baseline(attacks, days),
    );
  }

  /// Splits the recorded days into drop and calm, and counts how many of each
  /// the user had an attack on.
  ///
  /// Counts DAYS, not attacks: three attacks in one day is still one day that
  /// ended in an attack, and counting them separately would let a single bad
  /// day carry the whole comparison.
  ///
  /// Null when either side is too thin to state — see [minDaysPerSide].
  PressureBaseline? _baseline(List<Attack> attacks, List<DailyPressure> days) {
    if (days.isEmpty) return null;

    final Set<DateTime> attackDays = <DateTime>{
      for (final Attack attack in attacks)
        // Local, because "the day I had an attack" is a local idea and the
        // readings are keyed the same way.
        _dayOf(attack.startedAt.toLocal()),
    };
    int dropDays = 0;
    int dropWithAttack = 0;
    int calmDays = 0;
    int calmWithAttack = 0;

    for (final DailyPressure day in days) {
      final bool hadAttack = attackDays.contains(day.day);

      if (day.isDrop(dropThresholdHpa)) {
        dropDays++;
        if (hadAttack) dropWithAttack++;
      } else {
        calmDays++;
        if (hadAttack) calmWithAttack++;
      }
    }

    final PressureBaseline baseline = PressureBaseline(
      dropDays: dropDays,
      dropDaysWithAttack: dropWithAttack,
      calmDays: calmDays,
      calmDaysWithAttack: calmWithAttack,
      minDaysPerSide: minDaysPerSide,
    );

    return baseline.isReliable ? baseline : null;
  }

  static DateTime _dayOf(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
