import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/exertion_level.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';
import 'package:migraine_tracker/features/sync/domain/services/attack_payload_codec.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';

void main() {
  Attack full() => Attack(
    id: 'a1',
    startedAt: DateTime.utc(2026, 7, 1, 8, 30),
    intensity: 7,
    location: HeadLocation.right,
    medicationName: 'Sumatriptan',
    symptoms: const ['aura', 'nausea'],
    triggers: const ['stress'],
    notes: 'woke up with it',
    exertionLevel: ExertionLevel.moderate,
    weather: WeatherSnapshot(
      capturedAt: DateTime.utc(2026, 7, 1, 8),
      pressureHpa: 1008.2,
      pressureDelta24hHpa: -6,
      humidityPercent: 71.5,
      temperatureCelsius: 19.3,
    ),
  );

  test('every field survives the round trip', () {
    final Attack decoded = const AttackPayloadCodec().decode(
      const AttackPayloadCodec().encode(full()),
      id: 'a1',
    );

    expect(decoded.id, 'a1');
    expect(decoded.startedAt, DateTime.utc(2026, 7, 1, 8, 30));
    expect(decoded.intensity, 7);
    expect(decoded.location, HeadLocation.right);
    expect(decoded.medicationName, 'Sumatriptan');
    expect(decoded.symptoms, ['aura', 'nausea']);
    expect(decoded.triggers, ['stress']);
    expect(decoded.notes, 'woke up with it');
    expect(decoded.exertionLevel, ExertionLevel.moderate);
    expect(decoded.weather, full().weather);
  });

  test('an attack logged offline round-trips without weather', () {
    final Attack bare = Attack(
      id: 'a2',
      startedAt: DateTime.utc(2026, 7, 2),
      intensity: 4,
      location: HeadLocation.front,
    );

    final Attack decoded = const AttackPayloadCodec().decode(
      const AttackPayloadCodec().encode(bare),
      id: 'a2',
    );

    expect(decoded.weather, isNull);
    expect(decoded.medicationName, isNull);
    expect(decoded.notes, isNull);
    expect(decoded.exertionLevel, isNull);
    expect(decoded.symptoms, isEmpty);
  });

  test('the id comes from the document, not the payload', () {
    // The document id is the attack id, so carrying it twice invites drift.
    final Attack decoded = const AttackPayloadCodec().decode(
      const AttackPayloadCodec().encode(full()),
      id: 'different',
    );

    expect(decoded.id, 'different');
  });

  test('a local start time is normalised to UTC', () {
    final Attack local = Attack(
      id: 'a3',
      startedAt: DateTime(2026, 7, 3, 14),
      intensity: 5,
      location: HeadLocation.back,
    );

    final Attack decoded = const AttackPayloadCodec().decode(
      const AttackPayloadCodec().encode(local),
      id: 'a3',
    );

    expect(decoded.startedAt.isUtc, isTrue);
    expect(decoded.startedAt, local.startedAt);
  });

  test('the payload carries its version', () {
    final Object? json = jsonDecode(const AttackPayloadCodec().encode(full()));

    expect(
      (json! as Map<String, dynamic>)['v'],
      AttackPayloadCodec.schemaVersion,
    );
  });

  group('payload versions', () {
    test('a newer payload than this build knows is refused', () {
      final Map<String, dynamic> json =
          jsonDecode(const AttackPayloadCodec().encode(full()))
              as Map<String, dynamic>;
      json['v'] = AttackPayloadCodec.schemaVersion + 1;

      // Half-reading would overwrite a good local copy with a worse one.
      expect(
        () => const AttackPayloadCodec().decode(jsonEncode(json), id: 'a1'),
        throwsFormatException,
      );
    });

    test('an older payload still reads', () {
      final Map<String, dynamic> json =
          jsonDecode(const AttackPayloadCodec().encode(full()))
              as Map<String, dynamic>;
      json['v'] = 0;

      // The day the version is bumped, everything already uploaded is a
      // version behind. Refusing it would orphan the user's whole history.
      expect(
        const AttackPayloadCodec().decode(jsonEncode(json), id: 'a1').intensity,
        7,
      );
    });

    test('an unknown field is ignored rather than fatal', () {
      final Map<String, dynamic> json =
          jsonDecode(const AttackPayloadCodec().encode(full()))
              as Map<String, dynamic>;
      json['fieldFromALaterBuild'] = 'whatever';

      // Adding an optional field must not need a version bump, or two builds
      // in the wild could never read each other.
      expect(
        const AttackPayloadCodec().decode(jsonEncode(json), id: 'a1').notes,
        'woke up with it',
      );
    });

    test('a missing version is refused', () {
      final Map<String, dynamic> json =
          jsonDecode(const AttackPayloadCodec().encode(full()))
              as Map<String, dynamic>;
      json.remove('v');

      expect(
        () => const AttackPayloadCodec().decode(jsonEncode(json), id: 'a1'),
        throwsFormatException,
      );
    });
  });

  group('refuses what it cannot faithfully rebuild', () {
    test('an unknown head location', () {
      final Map<String, dynamic> json =
          jsonDecode(const AttackPayloadCodec().encode(full()))
              as Map<String, dynamic>;
      json['location'] = 'sideways';

      expect(
        () => const AttackPayloadCodec().decode(jsonEncode(json), id: 'a1'),
        throwsFormatException,
      );
    });

    test('a missing required field', () {
      final Map<String, dynamic> json =
          jsonDecode(const AttackPayloadCodec().encode(full()))
              as Map<String, dynamic>;
      json.remove('intensity');

      expect(
        () => const AttackPayloadCodec().decode(jsonEncode(json), id: 'a1'),
        throwsFormatException,
      );
    });

    test('something that is not an object at all', () {
      expect(
        () => const AttackPayloadCodec().decode('[]', id: 'a1'),
        throwsFormatException,
      );
    });
  });
}
