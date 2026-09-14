import '../entities/correlation_result.dart';
import '../entities/sleep_correlation_result.dart';
import '../entities/step_correlation_result.dart';
import '../entities/trigger_verdict.dart';

/// Answers the question the app was installed for: is weather actually your trigger?
class TriggerVerdictEngine {
  const TriggerVerdictEngine({this.meaningfulEffect = defaultMeaningfulEffect})
    : assert(
        meaningfulEffect > 0 && meaningfulEffect < 1,
        'meaningfulEffect is a share of the larger group, 0–1',
      );

  /// A fifth apart.
  static const double defaultMeaningfulEffect = 0.2;

  final double meaningfulEffect;

  TriggerVerdict analyze({
    required CorrelationResult pressure,
    required SleepCorrelationResult sleep,
    required StepCorrelationResult steps,
  }) {
    final TriggerStrength? pressureStrength = _pressure(pressure);
    final List<TriggerStrength> ranked = <TriggerStrength>[
      ?pressureStrength,
      if (_sleep(sleep) case final TriggerStrength strength) strength,
      if (_steps(steps) case final TriggerStrength strength) strength,
    ]..sort((a, b) => b.effect.compareTo(a.effect));

    // Nothing settled anywhere. Report how far along the pressure sample is, because that is the one the user is waiting on.
    if (ranked.isEmpty) {
      return TriggerVerdictPending(
        attacksAnalyzed: switch (pressure) {
          CorrelationInsufficientData(:final int attacksAnalyzed) ||
          CorrelationNoVariation(:final int attacksAnalyzed) ||
          CorrelationInsight(:final int attacksAnalyzed) => attacksAnalyzed,
        },
        requiredAttacks: switch (pressure) {
          CorrelationInsufficientData(:final int requiredAttacks) ||
          CorrelationNoVariation(:final int requiredAttacks) ||
          CorrelationInsight(:final int requiredAttacks) => requiredAttacks,
        },
      );
    }

    return TriggerVerdictAnswer(ranked: ranked, weather: pressureStrength);
  }

  /// Pressure counts only with a reliable baseline behind it.
  TriggerStrength? _pressure(CorrelationResult result) {
    if (result case CorrelationInsight(
      isPreliminary: false,
      baseline: final PressureBaseline baseline,
    ) when baseline.isReliable) {
      return _strength(
        TriggerFactor.pressure,
        baseline.dropDayAttackPercent,
        baseline.calmDayAttackPercent,
      );
    }

    return null;
  }

  TriggerStrength? _sleep(SleepCorrelationResult result) {
    if (result case SleepInsight(
      isPreliminary: false,
      :final Duration attackNightAverage,
      :final Duration restNightAverage,
    )) {
      return _strength(
        TriggerFactor.sleep,
        attackNightAverage.inMinutes.toDouble(),
        restNightAverage.inMinutes.toDouble(),
      );
    }

    return null;
  }

  TriggerStrength? _steps(StepCorrelationResult result) {
    if (result case StepInsight(
      isPreliminary: false,
      :final double attackDayAverage,
      :final double restDayAverage,
    )) {
      return _strength(TriggerFactor.steps, attackDayAverage, restDayAverage);
    }

    return null;
  }

  /// The gap as a share of the larger group, so a rate, a duration and a step count can be ordered against one another.
  TriggerStrength _strength(TriggerFactor factor, double a, double b) {
    final double larger = a > b ? a : b;

    return TriggerStrength(
      factor: factor,
      // Both sides at zero is no gap, not an undefined one.
      effect: larger == 0 ? 0 : (a - b).abs() / larger,
      meaningfulEffect: meaningfulEffect,
    );
  }
}
