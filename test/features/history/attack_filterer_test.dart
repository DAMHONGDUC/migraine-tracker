import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/aura_type.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/exertion_level.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/medication_effect.dart';
import 'package:migraine_tracker/features/history/domain/enums/attack_filters.dart';
import 'package:migraine_tracker/features/history/domain/enums/history_period.dart';
import 'package:migraine_tracker/features/history/domain/services/attack_filterer.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';

/// Wednesday 2026-07-08, 15:00 local — the same clock the period test runs on.
final DateTime now = DateTime(2026, 7, 8, 15);

Attack attack({
  String id = 'a',
  DateTime? startedAt,
  int intensity = 5,
  Duration? duration,
  List<AuraType>? aura,
  List<HeadRegion> regions = const <HeadRegion>[HeadRegion.templeL],
  String? medicationName,
  MedicationEffect? medicationEffect,
  List<String> symptoms = const <String>[],
  List<String> triggers = const <String>[],
  ExertionLevel? exertionLevel,
  String? notes,
  double? pressureDelta,
  bool weather = false,
}) {
  final DateTime started = startedAt ?? DateTime(2026, 7, 8, 9);

  return Attack(
    id: id,
    startedAt: started,
    intensity: intensity,
    regions: regions,
    aura: aura,
    medicationName: medicationName,
    medicationEffect: medicationEffect,
    symptoms: symptoms,
    triggers: triggers,
    exertionLevel: exertionLevel,
    notes: notes,
    endedAt: duration == null ? null : started.add(duration),
    weather: weather || pressureDelta != null
        ? WeatherSnapshot(
            capturedAt: started,
            pressureHpa: 1013,
            pressureDelta24hHpa: pressureDelta ?? 0,
          )
        : null,
  );
}

void main() {
  const AttackFilterer filterer = AttackFilterer();

  List<String> ids(List<Attack> attacks, AttackFilters filters) => filterer
      .apply(attacks, filters, now: now)
      .map((Attack attack) => attack.id)
      .toList();

  test('default filters keep every attack', () {
    final List<Attack> attacks = <Attack>[attack(id: 'a'), attack(id: 'b')];

    expect(ids(attacks, const AttackFilters()), <String>['a', 'b']);
    expect(const AttackFilters().isDefault, isTrue);
  });

  test('the axes AND together, period included', () {
    final List<Attack> attacks = <Attack>[
      attack(id: 'both', startedAt: DateTime(2026, 7, 8, 9), intensity: 2),
      attack(id: 'oldMild', startedAt: DateTime(2026, 6, 20), intensity: 2),
      attack(id: 'todayHard', startedAt: DateTime(2026, 7, 8, 10), intensity: 9),
    ];

    expect(
      ids(
        attacks,
        const AttackFilters(
          period: HistoryPeriod.today,
          intensity: IntensityFilter.mild,
        ),
      ),
      <String>['both'],
    );
  });

  test('an intensity band matches only its own band', () {
    final List<Attack> attacks = <Attack>[
      attack(id: 'mild', intensity: 3),
      attack(id: 'moderate', intensity: 4),
      attack(id: 'extreme', intensity: 9),
    ];

    expect(
      ids(attacks, const AttackFilters(intensity: IntensityFilter.moderate)),
      <String>['moderate'],
    );
  });

  group('duration', () {
    test('bands split on the 4h and 72h edges the diagnosis uses', () {
      expect(
        filterer.durationBandOf(const Duration(hours: 3, minutes: 59)),
        DurationFilter.under4h,
      );
      expect(
        filterer.durationBandOf(const Duration(hours: 4)),
        DurationFilter.from4To72h,
      );
      expect(
        filterer.durationBandOf(const Duration(hours: 72)),
        DurationFilter.from4To72h,
      );
      expect(
        filterer.durationBandOf(const Duration(hours: 72, minutes: 1)),
        DurationFilter.over72h,
      );
    });

    test('an attack with no end time is unrecorded, never dropped', () {
      final List<Attack> attacks = <Attack>[
        attack(id: 'open'),
        attack(id: 'closed', duration: const Duration(hours: 6)),
      ];

      expect(
        ids(attacks, const AttackFilters(duration: DurationFilter.unrecorded)),
        <String>['open'],
      );
    });
  });

  group('aura', () {
    final List<Attack> attacks = <Attack>[
      attack(id: 'visual', aura: const <AuraType>[AuraType.visual]),
      attack(id: 'motor', aura: const <AuraType>[AuraType.motor]),
      attack(id: 'answeredNone', aura: const <AuraType>[]),
      attack(id: 'neverAsked'),
    ];

    test('a kind matches the attacks reporting it', () {
      expect(
        ids(attacks, const AttackFilters(aura: AuraFilter.visual)),
        <String>['visual'],
      );
    });

    test('"no aura" covers both ways of not having one', () {
      expect(
        ids(attacks, const AttackFilters(aura: AuraFilter.none)),
        <String>['answeredNone', 'neverAsked'],
      );
    });
  });

  test('an area matches an attack naming any region on that side', () {
    final List<Attack> attacks = <Attack>[
      attack(
        id: 'leftTemple',
        regions: const <HeadRegion>[HeadRegion.templeL],
      ),
      attack(id: 'nape', regions: const <HeadRegion>[HeadRegion.nape]),
    ];

    expect(
      ids(attacks, const AttackFilters(area: AreaFilter.left)),
      <String>['leftTemple'],
    );
    expect(
      ids(attacks, const AttackFilters(area: AreaFilter.back)),
      <String>['nape'],
    );
  });

  group('medication', () {
    final List<Attack> attacks = <Attack>[
      attack(id: 'sumatriptan', medicationName: 'Sumatriptan'),
      attack(id: 'blank', medicationName: '   '),
      attack(id: 'none'),
    ];

    test('an empty name is the same answer as none', () {
      expect(
        ids(attacks, const AttackFilters(medication: MedicationFilter.notTaken)),
        <String>['blank', 'none'],
      );
    });

    test('a picked name matches whatever case it was written in', () {
      expect(
        ids(attacks, const AttackFilters(medicationName: 'sumatriptan')),
        <String>['sumatriptan'],
      );
    });

    test('an effect filter drops the attacks that never answered', () {
      final List<Attack> answered = <Attack>[
        attack(
          id: 'helped',
          medicationName: 'Sumatriptan',
          medicationEffect: MedicationEffect.helped,
        ),
        attack(id: 'unanswered', medicationName: 'Sumatriptan'),
      ];

      expect(
        ids(answered, const AttackFilters(effect: EffectFilter.helped)),
        <String>['helped'],
      );
    });
  });

  test('free text matches trimmed and case-folded', () {
    final List<Attack> attacks = <Attack>[
      attack(id: 'nausea', symptoms: const <String>['Nausea', 'photophobia']),
      attack(id: 'other', symptoms: const <String>['dizziness']),
    ];

    expect(
      ids(attacks, const AttackFilters(symptom: ' nausea ')),
      <String>['nausea'],
    );
  });

  test('exertion matches the recorded level only', () {
    final List<Attack> attacks = <Attack>[
      attack(id: 'severe', exertionLevel: ExertionLevel.severe),
      attack(id: 'unrecorded'),
    ];

    expect(
      ids(attacks, const AttackFilters(exertion: ExertionFilter.severe)),
      <String>['severe'],
    );
  });

  test('a whitespace-only note is no note', () {
    final List<Attack> attacks = <Attack>[
      attack(id: 'written', notes: 'started after coffee'),
      attack(id: 'spaces', notes: '  '),
    ];

    expect(
      ids(attacks, const AttackFilters(notes: NotesFilter.withNotes)),
      <String>['written'],
    );
  });

  group('pressure', () {
    test('the steady band is the ±1 hPa the widget already draws', () {
      expect(
        filterer.pressureTrendOf(attack(pressureDelta: -1)),
        PressureFilter.falling,
      );
      expect(
        filterer.pressureTrendOf(attack(pressureDelta: -0.9)),
        PressureFilter.steady,
      );
      expect(
        filterer.pressureTrendOf(attack(pressureDelta: 1)),
        PressureFilter.rising,
      );
    });

    test('an attack with no weather is its own answer', () {
      final List<Attack> attacks = <Attack>[
        attack(id: 'offline'),
        attack(id: 'backfilled', pressureDelta: -6.8),
      ];

      expect(
        ids(attacks, const AttackFilters(pressure: PressureFilter.noData)),
        <String>['offline'],
      );
    });
  });

  test('text options dedupe by case and keep the first spelling', () {
    final List<Attack> attacks = <Attack>[
      attack(id: 'a', symptoms: const <String>['Nausea', ' aura ']),
      attack(id: 'b', symptoms: const <String>['nausea', '']),
    ];

    expect(
      filterer.textOptions(attacks, (Attack attack) => attack.symptoms),
      <String>['Nausea', 'aura'],
    );
  });
}
