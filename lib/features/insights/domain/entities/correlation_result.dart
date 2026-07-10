import 'package:meta/meta.dart';

/// Outcome of a correlation analysis over the user's attack history.
@immutable
sealed class CorrelationResult {
  const CorrelationResult();
}

/// Not enough attacks with weather data to say anything meaningful.
class CorrelationInsufficientData extends CorrelationResult {
  const CorrelationInsufficientData({
    required this.attacksWithWeather,
    required this.requiredAttacks,
  });

  /// Attacks that had a weather snapshot attached (only these count).
  final int attacksWithWeather;
  final int requiredAttacks;
}

/// All snapshots show (nearly) identical pressure behaviour, so the drop
/// share carries no signal — e.g. a user in a climate with flat pressure.
class CorrelationNoVariation extends CorrelationResult {
  const CorrelationNoVariation({required this.attacksAnalyzed});

  final int attacksAnalyzed;
}

/// The headline insight: "X% of your attacks occurred during rapid
/// pressure drops."
class CorrelationInsight extends CorrelationResult {
  const CorrelationInsight({
    required this.attacksAnalyzed,
    required this.attacksDuringPressureDrop,
    required this.dropThresholdHpa,
  });

  final int attacksAnalyzed;
  final int attacksDuringPressureDrop;

  /// Threshold used to classify a snapshot as a "rapid drop" (hPa per 24h).
  final double dropThresholdHpa;

  /// Share of attacks during rapid drops, 0–100.
  double get dropSharePercent =>
      attacksDuringPressureDrop * 100 / attacksAnalyzed;
}
