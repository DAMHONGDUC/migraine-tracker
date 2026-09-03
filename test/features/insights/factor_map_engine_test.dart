import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/daily_log/domain/entities/daily_log.dart';
import 'package:migraine_tracker/features/daily_log/domain/enums/daily_factor.dart';
import 'package:migraine_tracker/features/insights/domain/entities/factor_association.dart';
import 'package:migraine_tracker/features/insights/domain/enums/map_factor.dart';
import 'package:migraine_tracker/features/insights/domain/services/factor_map_engine.dart';

void main() {
  const FactorMapEngine engine = FactorMapEngine();
  final DateTime start = DateTime(2026, 8, 1);

  DailyLog logOn(
    int dayOffset, {
    List<DailyFactor> factors = const <DailyFactor>[],
    int? sleepQuality,
    int? stressLevel,
  }) => DailyLog(
    day: start.add(Duration(days: dayOffset)),
    // Every day answered, so nothing is dropped for being a bare Health row.
    sleepQuality: sleepQuality ?? 3,
    stressLevel: stressLevel,
    factors: factors,
  );

  Attack attackOn(int dayOffset) => Attack(
    id: 'a$dayOffset',
    startedAt: start.add(Duration(days: dayOffset, hours: 9)),
    intensity: 6,
    regions: const <HeadRegion>[HeadRegion.templeR],
  );

  FactorAssociation associationOf(FactorMap map, MapFactor factor) =>
      map.associations.firstWhere((FactorAssociation a) => a.factor == factor);

  group('the gate', () {
    test('too few answered days is not ready, whatever the factors say', () {
      final FactorMap map = engine.analyze(
        logs: <DailyLog>[for (int i = 0; i < 10; i++) logOn(i)],
        attacks: <Attack>[for (int i = 0; i < 20; i++) attackOn(i)],
      );

      expect(map.isReady, isFalse);
      expect(map.answeredDays, 10);
      expect(map.requiredDays, 28);
    });

    test('too few attacks is not ready either', () {
      final FactorMap map = engine.analyze(
        logs: <DailyLog>[for (int i = 0; i < 40; i++) logOn(i)],
        attacks: <Attack>[for (int i = 0; i < 3; i++) attackOn(i)],
      );

      expect(map.isReady, isFalse);
      expect(map.attacks, 3);
    });

    // A row Health filled in with a step count says nothing about the day.
    test('an unanswered row does not count towards the days', () {
      final FactorMap map = engine.analyze(
        logs: <DailyLog>[
          for (int i = 0; i < 30; i++)
            DailyLog(day: start.add(Duration(days: i)), steps: 900),
        ],
        attacks: <Attack>[for (int i = 0; i < 20; i++) attackOn(i)],
      );

      expect(map.answeredDays, 0);
      expect(map.isReady, isFalse);
    });
  });

  group('the verdicts', () {
    // 10 days with alcohol, 8 of them ending in an attack; 20 without, 2 of them.
    test('a factor that attacks follow is a trigger', () {
      final FactorMap map = engine.analyze(
        logs: <DailyLog>[
          for (int i = 0; i < 10; i++)
            logOn(i, factors: const <DailyFactor>[DailyFactor.alcohol]),
          for (int i = 10; i < 30; i++) logOn(i),
        ],
        attacks: <Attack>[
          for (int i = 0; i < 8; i++) attackOn(i),
          for (int i = 10; i < 18; i++) attackOn(i),
        ],
      );
      final FactorAssociation alcohol = associationOf(map, MapFactor.alcohol);

      expect(map.isReady, isTrue);
      expect(alcohol.verdict, FactorVerdict.trigger);
      expect(alcohol.daysWith, 10);
      expect(alcohol.daysWithout, 20);
      expect(alcohol.attackRateWith, 0.8);
      expect(alcohol.attackRateWithout, 0.4);
    });

    // The mirror image: attacks avoid the days that carry it.
    test('a factor the quiet days carry is a protector', () {
      final FactorMap map = engine.analyze(
        logs: <DailyLog>[
          for (int i = 0; i < 10; i++)
            logOn(
              i,
              factors: const <DailyFactor>[DailyFactor.intenseExercise],
            ),
          for (int i = 10; i < 30; i++) logOn(i),
        ],
        attacks: <Attack>[
          attackOn(0),
          for (int i = 10; i < 26; i++) attackOn(i),
        ],
      );

      expect(
        associationOf(map, MapFactor.intenseExercise).verdict,
        FactorVerdict.protector,
      );
    });

    test('two groups that behave the same are not associated', () {
      final FactorMap map = engine.analyze(
        logs: <DailyLog>[
          for (int i = 0; i < 10; i++)
            logOn(i, factors: const <DailyFactor>[DailyFactor.caffeine]),
          for (int i = 10; i < 30; i++) logOn(i),
        ],
        attacks: <Attack>[
          for (int i = 0; i < 5; i++) attackOn(i),
          for (int i = 10; i < 20; i++) attackOn(i),
        ],
      );

      expect(
        associationOf(map, MapFactor.caffeine).verdict,
        FactorVerdict.notAssociated,
      );
    });

    // Four days against twenty-six is a coincidence with a percentage sign on it.
    test('too few days on one side is graded insufficient, not not-associated',
        () {
      final FactorMap map = engine.analyze(
        logs: <DailyLog>[
          for (int i = 0; i < 4; i++)
            logOn(i, factors: const <DailyFactor>[DailyFactor.travel]),
          for (int i = 4; i < 30; i++) logOn(i),
        ],
        attacks: <Attack>[for (int i = 0; i < 16; i++) attackOn(i)],
      );

      expect(
        associationOf(map, MapFactor.travel).verdict,
        FactorVerdict.insufficient,
      );
    });
  });

  group('the derived factors', () {
    test('a rating of 1 or 2 puts the day in the poor-sleep group', () {
      final FactorMap map = engine.analyze(
        logs: <DailyLog>[
          for (int i = 0; i < 10; i++) logOn(i, sleepQuality: 2),
          for (int i = 10; i < 30; i++) logOn(i, sleepQuality: 4),
        ],
        attacks: <Attack>[for (int i = 0; i < 9; i++) attackOn(i)],
      );
      final FactorAssociation poorSleep =
          associationOf(map, MapFactor.poorSleep);

      expect(poorSleep.daysWith, 10);
      expect(poorSleep.verdict, FactorVerdict.trigger);
    });

    // A rating nobody gave must not be read as a good night.
    test('an unrated night does not join the poor-sleep group', () {
      final FactorMap map = engine.analyze(
        logs: <DailyLog>[
          for (int i = 0; i < 30; i++)
            DailyLog(
              day: start.add(Duration(days: i)),
              stressLevel: 3,
            ),
        ],
        attacks: <Attack>[for (int i = 0; i < 16; i++) attackOn(i)],
      );

      expect(associationOf(map, MapFactor.poorSleep).daysWith, 0);
    });
  });

  // A factor with four days behind it can show an effect of 1.0; that is the four days talking, not a finding.
  test('an ungraded factor never leads the list', () {
    final FactorMap map = engine.analyze(
      logs: <DailyLog>[
        for (int i = 0; i < 10; i++)
          logOn(
            i,
            factors: const <DailyFactor>[
              DailyFactor.alcohol,
              DailyFactor.caffeine,
            ],
          ),
        for (int i = 10; i < 30; i++)
          logOn(i, factors: const <DailyFactor>[DailyFactor.caffeine]),
      ],
      attacks: <Attack>[
        for (int i = 0; i < 8; i++) attackOn(i),
        for (int i = 10; i < 18; i++) attackOn(i),
      ],
    );

    expect(map.associations.first.factor, MapFactor.alcohol);
  });
}
