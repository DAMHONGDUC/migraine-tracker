import '../../../attacks/domain/entities/attack.dart';
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
  }) : assert(minAttacks > 0, 'minAttacks must be positive'),
       assert(minAttacksForShare > 0, 'minAttacksForShare must be positive'),
       assert(dropThresholdHpa > 0, 'dropThresholdHpa must be positive');

  /// Where the share settles. The normal approximation behind any confidence
  /// claim needs ~5 attacks on each side of the threshold, which lands here
  /// when roughly a third of attacks fall during drops.
  static const int defaultMinAttacks = 15;

  /// Below this the result asks for counts instead of a percentage: at 1–4
  /// attacks a share can only be 0/25/33/50/100, all of which read as claims.
  static const int defaultMinAttacksForShare = 5;

  /// A 24h pressure drop of at least this many hPa counts as "rapid".
  static const double defaultDropThresholdHpa = 5.0;

  /// Two snapshots whose deltas differ less than this are "the same weather".
  static const double _variationEpsilonHpa = 0.5;

  final int minAttacks;
  final int minAttacksForShare;
  final double dropThresholdHpa;

  CorrelationResult analyze(List<Attack> attacks) {
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
    );
  }
}
