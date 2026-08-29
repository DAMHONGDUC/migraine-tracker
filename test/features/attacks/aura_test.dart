import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/db/app_database.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/aura_type.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/sync/domain/services/attack_payload_codec.dart';

Attack attack({List<AuraType>? aura}) => Attack(
  id: 'a1',
  startedAt: DateTime.utc(2026, 7, 1, 8),
  intensity: 6,
  regions: const <HeadRegion>[HeadRegion.templeR],
  aura: aura,
);

void main() {
  // Null and empty are different records on purpose.
  group('the repository', () {
    late AppDatabase db;
    late DriftAttackRepository repository;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repository = DriftAttackRepository(db);
    });

    tearDown(() => db.close());

    test('a new attack starts with the question unanswered', () async {
      await repository.insert(attack());

      expect((await repository.getAll()).single.aura, isNull);
    });

    test('records the kinds and reads them back', () async {
      await repository.insert(attack());

      await repository.updateAura('a1', <AuraType>[
        AuraType.visual,
        AuraType.speech,
      ]);

      expect((await repository.getAll()).single.aura, <AuraType>[
        AuraType.visual,
        AuraType.speech,
      ]);
    });

    test('an empty list is a recorded "no aura", not a cleared answer', () async {
      await repository.insert(attack(aura: <AuraType>[AuraType.visual]));

      await repository.updateAura('a1', const <AuraType>[]);

      expect((await repository.getAll()).single.aura, isEmpty);
    });

    test('null takes the answer back', () async {
      await repository.insert(attack(aura: const <AuraType>[]));

      await repository.updateAura('a1', null);

      expect((await repository.getAll()).single.aura, isNull);
    });

    // Its own method for the same reason updateExertion is: the details sheet never shows aura, so a save from there must not blank it.
    test('editing details leaves the aura alone', () async {
      await repository.insert(attack(aura: <AuraType>[AuraType.sensory]));

      await repository.updateDetails(
        'a1',
        symptoms: const <String>['nausea'],
        triggers: const <String>[],
      );

      expect((await repository.getAll()).single.aura, <AuraType>[
        AuraType.sensory,
      ]);
    });

    test('recording the aura marks the row for sync', () async {
      await repository.insert(attack());
      final AttackRow before = await (db.select(
        db.attacks,
      )..where((t) => t.id.equals('a1'))).getSingle();

      await repository.updateAura('a1', <AuraType>[AuraType.motor]);

      final AttackRow after = await (db.select(
        db.attacks,
      )..where((t) => t.id.equals('a1'))).getSingle();

      expect(after.revision, greaterThan(before.revision));
    });
  });

  group('the sync payload', () {
    const AttackPayloadCodec codec = AttackPayloadCodec();

    test('the kinds survive the round trip', () {
      final Attack decoded = codec.decode(
        codec.encode(
          attack(aura: <AuraType>[AuraType.visual, AuraType.motor]),
        ),
        id: 'a1',
      );

      expect(decoded.aura, <AuraType>[AuraType.visual, AuraType.motor]);
    });

    test('an empty list survives as an empty list', () {
      final Attack decoded = codec.decode(
        codec.encode(attack(aura: const <AuraType>[])),
        id: 'a1',
      );

      expect(decoded.aura, isEmpty);
      expect(decoded.aura, isNotNull);
    });

    test('an unanswered question survives as null', () {
      final Attack decoded = codec.decode(codec.encode(attack()), id: 'a1');

      expect(decoded.aura, isNull);
    });

    // Additive, so schemaVersion stays 1: a payload written before aura existed has no such key and must still decode.
    test('a payload written before aura decodes as unanswered', () {
      final Map<String, dynamic> payload =
          jsonDecode(codec.encode(attack(aura: <AuraType>[AuraType.visual])))
              as Map<String, dynamic>;

      payload.remove('aura');

      expect(codec.decode(jsonEncode(payload), id: 'a1').aura, isNull);
    });

    // The other direction: a build that learned a fifth kind must not make this one throw away the whole record.
    test('an unknown kind is dropped, never thrown on', () {
      final Map<String, dynamic> payload =
          jsonDecode(codec.encode(attack(aura: <AuraType>[AuraType.visual])))
              as Map<String, dynamic>;

      payload['aura'] = <String>['visual', 'retinal'];

      expect(codec.decode(jsonEncode(payload), id: 'a1').aura, <AuraType>[
        AuraType.visual,
      ]);
    });
  });
}
