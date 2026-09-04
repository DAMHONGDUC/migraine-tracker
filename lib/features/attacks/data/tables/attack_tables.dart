import 'package:drift/drift.dart';

import '../../../../core/db/converters.dart';
import '../../domain/enums/exertion_level.dart';
import '../../domain/enums/medication_effect.dart';

@DataClassName('AttackRow')
class Attacks extends Table {
  TextColumn get id => text()();

  /// Stored as UTC unix timestamp.
  DateTimeColumn get startedAt => dateTime()();

  IntColumn get intensity => integer()();
  /// Every head area the user tapped, JSON-encoded.
  TextColumn get regions => text()
      .map(const HeadRegionListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get medicationName => text().nullable()();
  TextColumn get symptoms => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get triggers => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get notes => text().nullable()();
  TextColumn get exertionLevel => textEnum<ExertionLevel>().nullable()();

  /// Whether the medication helped. Null is "never answered", which also covers every attack where nothing was taken.
  TextColumn get medicationEffect =>
      textEnum<MedicationEffect>().nullable()();

  /// Aura kinds reported for this attack, JSON-encoded.
  TextColumn get aura =>
      text().map(const AuraTypeListConverter()).nullable()();

  /// When the medication was taken, UTC. Null is "never said" — the same state as an attack where nothing was taken.
  DateTimeColumn get medicationTakenAt => dateTime().nullable()();

  /// When the pain eased, UTC. Its own column rather than a duration, because a duration cannot say WHEN without a second field anyway.
  DateTimeColumn get reliefAt => dateTime().nullable()();

  /// When the attack stopped, UTC. Null is "still going, or never said" — one state on purpose, since nothing here can tell those apart.
  DateTimeColumn get endedAt => dateTime().nullable()();

  /// Steps that day up to the log, from Apple Health. Nullable because the source is optional in every sense: not iOS, not granted, or no samples.
  IntColumn get steps => integer().nullable()();

  /// Wall clock of the last local mutation, used only to settle which of two devices' versions wins.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  /// Bumped on every local mutation.
  IntColumn get revision => integer().withDefault(const Constant(0))();

  /// The [revision] the server confirmed. Dirty is `syncedRevision != revision`, so a clock stepping backwards cannot hide an edit either.
  IntColumn get syncedRevision => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One optional snapshot per attack; missing while the attack was logged offline, backfilled later.
@DataClassName('WeatherSnapshotRow')
class WeatherSnapshots extends Table {
  TextColumn get attackId =>
      text().references(Attacks, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get capturedAt => dateTime()();
  RealColumn get pressureHpa => real()();
  RealColumn get pressureDelta24hHpa => real()();
  RealColumn get humidityPercent => real().nullable()();
  RealColumn get temperatureCelsius => real().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {attackId};
}
