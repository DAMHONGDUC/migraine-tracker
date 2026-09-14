import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/core/utils/date_time_utils.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/exertion_level.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';

void main() {
  late AppDatabase db;
  late DriftAttackRepository repository;

  Attack attack({DateTime? endedAt}) => Attack(
    id: 'a1',
    startedAt: DateTime.utc(2026, 7, 1, 8),
    intensity: 7,
    regions: const <HeadRegion>[HeadRegion.templeR],
    exertionLevel: ExertionLevel.moderate,
    endedAt: endedAt,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftAttackRepository(db);
  });

  tearDown(() => db.close());

  group('the entity', () {
    test('duration is the gap between start and end', () {
      expect(
        attack(endedAt: DateTime.utc(2026, 7, 1, 14, 30)).duration,
        const Duration(hours: 6, minutes: 30),
      );
    });

    // "Still going" and "never said" are one state on purpose.
    test('no end means no duration', () {
      expect(attack().duration, isNull);
    });

    test('a local end time is stored as UTC', () {
      final Attack a = attack(endedAt: DateTime(2026, 7, 1, 20));

      expect(a.endedAt!.isUtc, isTrue);
    });

    test('an attack cannot end before it started', () {
      expect(
        () => attack(endedAt: DateTime.utc(2026, 7, 1, 7)),
        throwsA(isA<AssertionError>()),
      );
    });

    test(
      'ending in the same instant it started is a zero duration, not an error',
      () {
        expect(
          attack(endedAt: DateTime.utc(2026, 7, 1, 8)).duration,
          Duration.zero,
        );
      },
    );
  });

  group('the repository', () {
    test('records the end and reads it back', () async {
      await repository.insert(attack());

      await repository.updateEndedAt('a1', DateTime.utc(2026, 7, 1, 14));

      final Attack stored = (await repository.getAll()).single;

      expect(stored.endedAt, DateTime.utc(2026, 7, 1, 14));
      expect(stored.duration, const Duration(hours: 6));
    });

    test('takes the answer back on null', () async {
      await repository.insert(attack(endedAt: DateTime.utc(2026, 7, 1, 14)));

      await repository.updateEndedAt('a1', null);

      expect((await repository.getAll()).single.endedAt, isNull);
    });

    // Its own method for the same reason updateExertion is: the details sheet never shows the duration, so a save from there must not blank it.
    test('editing details leaves the end alone', () async {
      await repository.insert(attack(endedAt: DateTime.utc(2026, 7, 1, 14)));

      await repository.updateDetails(
        'a1',
        symptoms: const <String>['aura'],
        triggers: const <String>[],
        notes: 'later',
      );

      final Attack stored = (await repository.getAll()).single;

      expect(stored.endedAt, DateTime.utc(2026, 7, 1, 14));
      expect(stored.symptoms, <String>['aura']);
    });

    test('correcting the core fields leaves the end alone', () async {
      await repository.insert(attack(endedAt: DateTime.utc(2026, 7, 1, 14)));

      await repository.updateCore(
        'a1',
        intensity: 3,
        regions: const <HeadRegion>[HeadRegion.templeL],
      );

      expect(
        (await repository.getAll()).single.endedAt,
        DateTime.utc(2026, 7, 1, 14),
      );
    });

    // Every mutation has to mark the row dirty or the edit never leaves the device (hard rule 12).
    test('recording the end marks the row for sync', () async {
      await repository.insert(attack());
      final AttackRow before = await (db.select(
        db.attacks,
      )..where((t) => t.id.equals('a1'))).getSingle();

      await repository.updateEndedAt('a1', DateTime.utc(2026, 7, 1, 14));

      final AttackRow after = await (db.select(
        db.attacks,
      )..where((t) => t.id.equals('a1'))).getSingle();

      expect(after.revision, greaterThan(before.revision));
      expect(after.syncedRevision, isNot(after.revision));
    });
  });

  group('the median the report states', () {
    test('is the middle value, not the mean', () {
      // A mean would be dragged to ~19h by the outlier; no attack was that.
      expect(
        DateTimeUtils.median(const <Duration>[
          Duration(hours: 2),
          Duration(hours: 4),
          Duration(hours: 6),
          Duration(hours: 72),
        ]),
        const Duration(hours: 5),
      );
    });

    test('is the middle one for an odd count', () {
      expect(
        DateTimeUtils.median(const <Duration>[
          Duration(hours: 6),
          Duration(hours: 1),
          Duration(hours: 4),
        ]),
        const Duration(hours: 4),
      );
    });

    test('is null when nobody timed anything', () {
      expect(DateTimeUtils.median(const <Duration>[]), isNull);
    });
  });
}
