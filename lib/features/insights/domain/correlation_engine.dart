import '../../attacks/domain/attack.dart';
import 'correlation_result.dart';

/// Correlation engine v1: what share of attacks happened during a rapid
/// barometric pressure drop?
///
/// Pure Dart, deterministic, timezone-agnostic: it only looks at the
/// pressure deltas already attached to each attack's weather snapshot, never
/// at wall-clock time.
class CorrelationEngine {
  const CorrelationEngine({
    this.minAttacks = defaultMinAttacks,
    this.dropThresholdHpa = defaultDropThresholdHpa,
  }) : assert(minAttacks > 0, 'minAttacks must be positive'),
       assert(dropThresholdHpa > 0, 'dropThresholdHpa must be positive');

  /// Below this many attacks-with-weather the insight is statistically
  /// meaningless noise (see PLAN.md §4).
  static const int defaultMinAttacks = 15;

  /// A 24h pressure drop of at least this many hPa counts as "rapid".
  static const double defaultDropThresholdHpa = 5.0;

  /// Two snapshots whose deltas differ less than this are "the same weather".
  static const double _variationEpsilonHpa = 0.5;

  final int minAttacks;
  final double dropThresholdHpa;

  CorrelationResult analyze(List<Attack> attacks) {
    final withWeather = attacks.where((a) => a.weather != null).toList();

    if (withWeather.length < minAttacks) {
      return CorrelationInsufficientData(
        attacksWithWeather: withWeather.length,
        requiredAttacks: minAttacks,
      );
    }

    final deltas = withWeather
        .map((a) => a.weather!.pressureDelta24hHpa)
        .toList();

    final min = deltas.reduce((a, b) => a < b ? a : b);
    final max = deltas.reduce((a, b) => a > b ? a : b);
    if (max - min < _variationEpsilonHpa) {
      return CorrelationNoVariation(attacksAnalyzed: withWeather.length);
    }

    final duringDrop = deltas.where((d) => d <= -dropThresholdHpa).length;

    return CorrelationInsight(
      attacksAnalyzed: withWeather.length,
      attacksDuringPressureDrop: duringDrop,
      dropThresholdHpa: dropThresholdHpa,
    );
  }
}
