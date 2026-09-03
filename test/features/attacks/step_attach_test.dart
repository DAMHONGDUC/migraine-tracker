import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/aura_type.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/exertion_level.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/medication_effect.dart';
import 'package:migraine_tracker/features/attacks/domain/repositories/attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/services/step_attach_service.dart';
import 'package:migraine_tracker/features/health/domain/entities/sleep_night.dart';
import 'package:migraine_tracker/features/health/domain/entities/step_day.dart';
import 'package:migraine_tracker/features/health/domain/entities/step_hour.dart';
import 'package:migraine_tracker/features/health/domain/enums/health_data_kind.dart';
import 'package:migraine_tracker/features/health/domain/repositories/health_repository.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';

/// Records what was attached and nothing else — every other method is here only because the interface has it.
class _Attacks implements AttackRepository {
  final Map<String, int> attachedSteps = <String, int>{};

  @override
  Future<void> attachSteps(String attackId, int steps) async =>
      attachedSteps[attackId] = steps;

  @override
  Stream<List<Attack>> watchAll() => const Stream<List<Attack>>.empty();

  @override
  Future<List<Attack>> getAll() async => const <Attack>[];

  @override
  Stream<Attack?> watchById(String id) => const Stream<Attack?>.empty();

  @override
  Future<void> insert(Attack attack) async {}

  @override
  Future<void> attachWeather(String attackId, WeatherSnapshot weather) async {}

  @override
  Future<void> updateMedicationTiming(
    String id, {
    required DateTime? takenAt,
    required DateTime? reliefAt,
  }) async {}

  @override
  Future<List<Attack>> attacksMissingWeather() async => const <Attack>[];

  @override
  Future<void> updateDetails(
    String id, {
    required List<String> symptoms,
    required List<String> triggers,
    String? notes,
  }) async {}

  @override
  Future<void> updateExertion(String id, ExertionLevel? exertionLevel) async {}

  @override
  Future<void> updateEndedAt(String id, DateTime? endedAt) async {}

  @override
  Future<void> updateMedicationEffect(
    String id,
    MedicationEffect? effect,
  ) async {}

  @override
  Future<void> updateAura(String id, List<AuraType>? aura) async {}

  @override
  Future<void> updateCore(
    String id, {
    required int intensity,
    required List<HeadRegion> regions,
    String? medicationName,
  }) async {}

  @override
  Future<void> deleteById(String id) async {}

  @override
  Future<void> deleteAll() async {}
}

class _Health implements HealthRepository {
  _Health({
    this.available = true,
    this.days = const <StepDay>[],
    this.throws = false,
  });

  final bool available;
  final List<StepDay> days;
  final bool throws;
  DateTime? from;
  DateTime? to;

  @override
  bool get isAvailable => available;

  @override
  Future<List<StepDay>> stepDays({
    required DateTime from,
    required DateTime to,
  }) async {
    this.from = from;
    this.to = to;
    if (throws) throw Exception('HealthKit said no');
    return days;
  }

  @override
  Future<List<SleepNight>> sleepNights({
    required DateTime from,
    required DateTime to,
  }) async => const <SleepNight>[];

  @override
  Future<List<StepHour>> stepHours({
    required DateTime from,
    required DateTime to,
  }) async => const <StepHour>[];

  @override
  Future<bool> requestAuthorization(HealthDataKind kind) async => true;
}

void main() {
  final DateTime loggedAt = DateTime(2026, 8, 20, 14, 30).toUtc();

  Attack attack() => Attack(
    id: 'a1',
    startedAt: loggedAt,
    intensity: 6,
    regions: const <HeadRegion>[HeadRegion.templeL],
  );

  test('attaches the steps taken between midnight and the log', () async {
    final _Attacks attacks = _Attacks();
    final _Health health = _Health(
      days: <StepDay>[StepDay(date: DateTime(2026, 8, 20), count: 4210)],
    );

    await StepAttachService(attacks, health).onAttackLogged(attack());

    expect(attacks.attachedSteps, <String, int>{'a1': 4210});
    // The window ends at the log, not at the end of the day: the number is how much the user had moved BEFORE the attack.
    expect(health.to, loggedAt.toLocal());
    expect(health.from, DateTime(2026, 8, 20));
  });

  test('attaches nothing when Health has nothing to give', () async {
    final _Attacks attacks = _Attacks();

    await StepAttachService(attacks, _Health()).onAttackLogged(attack());

    // Null and zero are different answers — an absent day must not be filed as a day spent still.
    expect(attacks.attachedSteps, isEmpty);
  });

  test('does not touch Health off iOS', () async {
    final _Attacks attacks = _Attacks();
    final _Health health = _Health(available: false);

    await StepAttachService(attacks, health).onAttackLogged(attack());

    expect(health.from, isNull);
    expect(attacks.attachedSteps, isEmpty);
  });

  test('a Health failure costs the number, never the attack', () async {
    final _Attacks attacks = _Attacks();

    await StepAttachService(
      attacks,
      _Health(throws: true),
    ).onAttackLogged(attack());

    expect(attacks.attachedSteps, isEmpty);
  });
}
