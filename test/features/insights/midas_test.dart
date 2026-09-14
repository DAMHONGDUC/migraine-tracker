import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/insights/data/repositories/drift_midas_repository.dart';
import 'package:migraine_tracker/features/insights/domain/entities/midas_score.dart';
import 'package:migraine_tracker/features/sync/domain/services/midas_payload_codec.dart';

void main() {
  MidasEntry entry({
    String id = 'm1',
    int missedWork = 0,
    int reducedWork = 0,
    int missedHousehold = 0,
    int reducedHousehold = 0,
    int missedSocial = 0,
  }) => MidasEntry(
    id: id,
    takenAt: DateTime.utc(2026, 9, 1, 10),
    missedWorkDays: missedWork,
    reducedWorkDays: reducedWork,
    missedHouseholdDays: missedHousehold,
    reducedHouseholdDays: reducedHousehold,
    missedSocialDays: missedSocial,
  );

  group('the score', () {
    test('it is the five answers added, and nothing else', () {
      expect(
        entry(
          missedWork: 3,
          reducedWork: 4,
          missedHousehold: 2,
          reducedHousehold: 1,
          missedSocial: 4,
        ).score,
        14,
      );
    });

    // The published cut-offs: I 0-5, II 6-10, III 11-20, IV 21+.
    test('the grades sit on the published cut-offs', () {
      expect(MidasEntry.gradeOf(0), MidasGrade.littleOrNone);
      expect(MidasEntry.gradeOf(5), MidasGrade.littleOrNone);
      expect(MidasEntry.gradeOf(6), MidasGrade.mild);
      expect(MidasEntry.gradeOf(10), MidasGrade.mild);
      expect(MidasEntry.gradeOf(11), MidasGrade.moderate);
      expect(MidasEntry.gradeOf(20), MidasGrade.moderate);
      expect(MidasEntry.gradeOf(21), MidasGrade.severe);
    });
  });

  group('the repository', () {
    late AppDatabase db;
    late DriftMidasRepository repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repository = DriftMidasRepository(db);
    });

    tearDown(() => db.close());

    // Every save is its own reading of a three-month window, so a re-take never overwrites the last one.
    test('the newest entry is the one the report reads', () async {
      await repository.upsert(entry(missedWork: 4));
      await repository.upsert(
        MidasEntry(
          id: 'm2',
          takenAt: DateTime.utc(2026, 9, 30, 10),
          missedWorkDays: 12,
          reducedWorkDays: 0,
          missedHouseholdDays: 0,
          reducedHouseholdDays: 0,
          missedSocialDays: 0,
        ),
      );

      expect((await repository.latest())!.score, 12);
      expect(await repository.watchAll().first, hasLength(2));
    });

    test('deleteAll leaves nothing behind', () async {
      await repository.upsert(entry(missedWork: 4));
      await repository.deleteAll();

      expect(await repository.latest(), isNull);
      expect(await db.select(db.syncTombstones).get(), isEmpty);
    });
  });

  group('the payload', () {
    const MidasPayloadCodec codec = MidasPayloadCodec();

    test('a questionnaire survives a round trip', () {
      final MidasEntry value = entry(
        missedWork: 3,
        reducedWork: 4,
        missedHousehold: 2,
        reducedHousehold: 1,
        missedSocial: 4,
      );

      final MidasEntry back = codec.decode(codec.encode(value), id: 'm1');

      expect(back.score, 14);
      expect(back.takenAt, value.takenAt);
      expect(back.grade, MidasGrade.moderate);
    });

    // One bad field must not cost the whole questionnaire.
    test('an impossible count reads as zero', () {
      const String json =
          '{"v":1,"takenAt":"2026-09-01T10:00:00.000Z","missedWorkDays":-4,'
          '"reducedWorkDays":2,"missedHouseholdDays":null,'
          '"reducedHouseholdDays":0,"missedSocialDays":1}';

      expect(codec.decode(json, id: 'm1').score, 3);
    });

    test('a newer payload version is refused', () {
      expect(() => codec.decode('{"v":99}', id: 'm1'), throwsFormatException);
    });
  });
}
