import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/sync/domain/services/attack_payload_codec.dart';

void main() {
  late AppDatabase db;
  late DriftAttackRepository repository;

  Attack attack({DateTime? takenAt, DateTime? reliefAt}) => Attack(
    id: 'a1',
    startedAt: DateTime.utc(2026, 7, 1, 8),
    intensity: 7,
    regions: const <HeadRegion>[HeadRegion.templeR],
    medicationName: 'Sumatriptan',
    medicationTakenAt: takenAt,
    reliefAt: reliefAt,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftAttackRepository(db);
  });

  tearDown(() => db.close());

  group('the entity', () {
    test('time to relief is measured from the dose, not from the attack', () {
      final Attack a = attack(
        takenAt: DateTime.utc(2026, 7, 1, 8, 20),
        reliefAt: DateTime.utc(2026, 7, 1, 9, 5),
      );

      expect(a.timeToRelief, const Duration(minutes: 45));
    });

    // Half an answer measures nothing, and must not be shown as if it did.
    test('a dose with no relief has no time to relief', () {
      expect(
        attack(takenAt: DateTime.utc(2026, 7, 1, 8, 20)).timeToRelief,
        isNull,
      );
    });

    test('neither half answered has no time to relief', () {
      expect(attack().timeToRelief, isNull);
    });
  });

  group('the repository', () {
    test('records both halves together', () async {
      await repository.insert(attack());
      await repository.updateMedicationTiming(
        'a1',
        takenAt: DateTime.utc(2026, 7, 1, 8, 30),
        reliefAt: DateTime.utc(2026, 7, 1, 9, 30),
      );

      final Attack stored = (await repository.getAll()).single;

      expect(stored.medicationTakenAt, DateTime.utc(2026, 7, 1, 8, 30));
      expect(stored.timeToRelief, const Duration(hours: 1));
    });

    test('clearing takes both halves back', () async {
      await repository.insert(
        attack(
          takenAt: DateTime.utc(2026, 7, 1, 8, 30),
          reliefAt: DateTime.utc(2026, 7, 1, 9, 30),
        ),
      );
      await repository.updateMedicationTiming(
        'a1',
        takenAt: null,
        reliefAt: null,
      );

      final Attack stored = (await repository.getAll()).single;

      expect(stored.medicationTakenAt, isNull);
      expect(stored.reliefAt, isNull);
    });

    // Sync only pushes what looks changed, so an edit that leaves the revision alone never leaves the device.
    test('an edit marks the attack dirty', () async {
      await repository.insert(attack());
      final int before = (await db.select(db.attacks).getSingle()).revision;

      await repository.updateMedicationTiming(
        'a1',
        takenAt: DateTime.utc(2026, 7, 1, 8, 30),
        reliefAt: null,
      );

      expect(
        (await db.select(db.attacks).getSingle()).revision,
        greaterThan(before),
      );
    });
  });

  group('the payload', () {
    const AttackPayloadCodec codec = AttackPayloadCodec();

    test('carries both times through a round trip', () {
      final Attack value = attack(
        takenAt: DateTime.utc(2026, 7, 1, 8, 30),
        reliefAt: DateTime.utc(2026, 7, 1, 9, 15),
      );

      final Attack back = codec.decode(codec.encode(value), id: 'a1');

      expect(back.medicationTakenAt, value.medicationTakenAt);
      expect(back.reliefAt, value.reliefAt);
      expect(back.timeToRelief, const Duration(minutes: 45));
    });

    // The fields are optional and additive, so a payload written before they existed still opens.
    test('a payload without them reads as unanswered', () {
      final String json = codec.encode(attack());

      expect(json.contains('"medicationTakenAt":null'), isTrue);
      expect(codec.decode(json, id: 'a1').medicationTakenAt, isNull);
      expect(AttackPayloadCodec.schemaVersion, 1);
    });
  });
}
