import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/insights/domain/entities/correlation_result.dart';
import 'package:migraine_tracker/features/insights/domain/entities/sleep_correlation_result.dart';
import 'package:migraine_tracker/features/insights/domain/entities/step_correlation_result.dart';
import 'package:migraine_tracker/features/insights/domain/entities/trigger_verdict.dart';
import 'package:migraine_tracker/features/insights/domain/services/trigger_verdict_engine.dart';

/// A settled pressure insight whose drop days ended in an attack [dropPercent]% of the time against [calmPercent]% of quiet days.
CorrelationResult pressure({
  required int dropPercent,
  required int calmPercent,
  int daysPerSide = 20,
  bool reliable = true,
  bool settled = true,
}) => CorrelationInsight(
  attacksAnalyzed: settled ? 30 : 4,
  requiredAttacks: 15,
  attacksDuringPressureDrop: 10,
  dropThresholdHpa: 5,
  minAttacksForShare: 5,
  baseline: PressureBaseline(
    dropDays: reliable ? daysPerSide : 2,
    dropDaysWithAttack: (daysPerSide * dropPercent / 100).round(),
    calmDays: reliable ? daysPerSide : 2,
    calmDaysWithAttack: (daysPerSide * calmPercent / 100).round(),
    minDaysPerSide: 5,
  ),
);

SleepCorrelationResult sleep({
  required int attackMinutes,
  required int restMinutes,
  bool settled = true,
}) => SleepInsight(
  attackNightAverage: Duration(minutes: attackMinutes),
  restNightAverage: Duration(minutes: restMinutes),
  attackNights: settled ? 20 : 2,
  restNights: settled ? 40 : 2,
  requiredNights: 15,
  requiredPerGroup: 3,
);

StepCorrelationResult steps({
  required double attackAverage,
  required double restAverage,
}) => StepInsight(
  attackDayAverage: attackAverage,
  restDayAverage: restAverage,
  attackDays: 20,
  restDays: 40,
  requiredDays: 15,
  requiredPerGroup: 3,
);

void main() {
  const TriggerVerdictEngine engine = TriggerVerdictEngine();

  const CorrelationResult noPressure = CorrelationInsufficientData(
    attacksAnalyzed: 3,
    requiredAttacks: 15,
  );
  const SleepCorrelationResult noSleep = SleepNotConnected();
  const StepCorrelationResult noSteps = StepNotConnected();

  group('pending', () {
    test('nothing settled is pending, never a verdict of no', () {
      final TriggerVerdict verdict = engine.analyze(
        pressure: noPressure,
        sleep: noSleep,
        steps: noSteps,
      );

      expect(verdict, isA<TriggerVerdictPending>());
      verdict as TriggerVerdictPending;
      expect(verdict.attacksAnalyzed, 3);
      expect(verdict.requiredAttacks, 15);
    });

    test('a preliminary pressure sample does not rule the weather out', () {
      final TriggerVerdict verdict = engine.analyze(
        pressure: pressure(dropPercent: 20, calmPercent: 20, settled: false),
        sleep: noSleep,
        steps: noSteps,
      );

      expect(verdict, isA<TriggerVerdictPending>());
    });

    // The share alone is high for anyone living somewhere stormy and says nothing about cause, so it may never carry a verdict on its own.
    test('an unreliable baseline does not rule the weather out either', () {
      final TriggerVerdict verdict = engine.analyze(
        pressure: pressure(dropPercent: 50, calmPercent: 10, reliable: false),
        sleep: noSleep,
        steps: noSteps,
      );

      expect(verdict, isA<TriggerVerdictPending>());
    });
  });

  group('weather confirmed', () {
    test('a wide gap on drop days makes weather the trigger', () {
      final TriggerVerdict verdict = engine.analyze(
        pressure: pressure(dropPercent: 45, calmPercent: 15),
        sleep: noSleep,
        steps: noSteps,
      );

      final TriggerVerdictAnswer answer = verdict as TriggerVerdictAnswer;

      expect(answer.weatherIsATrigger, isTrue);
      expect(answer.weatherRuledOut, isFalse);
      expect(answer.strongest!.factor, TriggerFactor.pressure);
      expect(answer.alternative, isNull);
    });
  });

  group('weather ruled out', () {
    test('an attack rate that barely differs is not a trigger', () {
      final TriggerVerdict verdict = engine.analyze(
        pressure: pressure(dropPercent: 20, calmPercent: 20),
        sleep: noSleep,
        steps: noSteps,
      );

      final TriggerVerdictAnswer answer = verdict as TriggerVerdictAnswer;

      expect(answer.weatherRuledOut, isTrue);
      expect(answer.weatherIsATrigger, isFalse);
    });

    // The sentence that keeps a user who installed this for the weather.
    test('and it names what does look like the trigger instead', () {
      final TriggerVerdict verdict = engine.analyze(
        pressure: pressure(dropPercent: 21, calmPercent: 20),
        sleep: sleep(attackMinutes: 5 * 60, restMinutes: 8 * 60),
        steps: noSteps,
      );

      final TriggerVerdictAnswer answer = verdict as TriggerVerdictAnswer;

      expect(answer.weatherRuledOut, isTrue);
      expect(answer.alternative!.factor, TriggerFactor.sleep);
      expect(answer.strongest!.factor, TriggerFactor.sleep);
    });

    test('a weak alternative is not offered as one', () {
      final TriggerVerdict verdict = engine.analyze(
        pressure: pressure(dropPercent: 20, calmPercent: 20),
        sleep: sleep(attackMinutes: 7 * 60 + 20, restMinutes: 7 * 60 + 30),
        steps: noSteps,
      );

      final TriggerVerdictAnswer answer = verdict as TriggerVerdictAnswer;

      expect(answer.weatherRuledOut, isTrue);
      expect(answer.alternative, isNull);
    });
  });

  group('ranking', () {
    test('the widest gap comes first whatever the unit', () {
      final TriggerVerdict verdict = engine.analyze(
        pressure: pressure(dropPercent: 30, calmPercent: 20),
        sleep: sleep(attackMinutes: 6 * 60, restMinutes: 7 * 60),
        steps: steps(attackAverage: 2000, restAverage: 8000),
      );

      final TriggerVerdictAnswer answer = verdict as TriggerVerdictAnswer;

      expect(answer.ranked.map((s) => s.factor), <TriggerFactor>[
        TriggerFactor.steps,
        TriggerFactor.pressure,
        TriggerFactor.sleep,
      ]);
    });

    test('weather can be a real trigger and still not be the strongest', () {
      final TriggerVerdict verdict = engine.analyze(
        pressure: pressure(dropPercent: 30, calmPercent: 20),
        sleep: sleep(attackMinutes: 4 * 60, restMinutes: 8 * 60),
        steps: noSteps,
      );

      final TriggerVerdictAnswer answer = verdict as TriggerVerdictAnswer;

      expect(answer.weatherIsATrigger, isTrue);
      expect(answer.strongest!.factor, TriggerFactor.sleep);
      expect(answer.alternative!.factor, TriggerFactor.sleep);
    });

    test('two groups both at zero is no gap, not a crash', () {
      final TriggerVerdict verdict = engine.analyze(
        pressure: pressure(dropPercent: 0, calmPercent: 0),
        sleep: noSleep,
        steps: noSteps,
      );

      final TriggerVerdictAnswer answer = verdict as TriggerVerdictAnswer;

      expect(answer.weather!.effect, 0);
      expect(answer.weatherRuledOut, isTrue);
    });
  });
}
