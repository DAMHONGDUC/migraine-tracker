import 'package:drift/drift.dart';

import '../../../../core/db/converters.dart';
import '../../domain/enums/exertion_level.dart';
import '../../domain/enums/head_location.dart';

@DataClassName('AttackRow')
class Attacks extends Table {
  TextColumn get id => text()();

  /// Stored as UTC unix timestamp.
  DateTimeColumn get startedAt => dateTime()();

  IntColumn get intensity => integer()();
  TextColumn get location => textEnum<HeadLocation>()();
  TextColumn get medicationName => text().nullable()();
  TextColumn get symptoms => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get triggers => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get notes => text().nullable()();
  TextColumn get exertionLevel => textEnum<ExertionLevel>().nullable()();

  /// Wall clock of the last local mutation, used only to settle which of two
  /// devices' versions wins. Null on rows that predate sync, which then fall
  /// back to [startedAt] — the best "last modified" we actually have.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  /// Bumped on every local mutation. Deliberately not a timestamp: drift
  /// stores dates as whole seconds, so an edit in the same second as the
  /// push that preceded it would look unchanged and never sync.
  IntColumn get revision => integer().withDefault(const Constant(0))();

  /// The [revision] the server confirmed. Dirty is `syncedRevision !=
  /// revision`, so a clock stepping backwards cannot hide an edit either.
  IntColumn get syncedRevision => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A deleted attack's id, kept only until the server is told about the
/// deletion. Without it, a delete on this device is resurrected by the next
/// pull from another one.
///
/// Deliberately a table of its own rather than a flag on [Attacks]: the
/// attack row is really gone the moment the user deletes it, so no intensity,
/// location or note outlives a delete. All that survives is the opaque UUID.
@DataClassName('AttackTombstoneRow')
class AttackTombstones extends Table {
  TextColumn get id => text()();

  /// Doubles as the row's `updatedAt` when a deletion races an edit made on
  /// another device — latest wins either way.
  DateTimeColumn get deletedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One optional snapshot per attack; missing while the attack was logged
/// offline, backfilled later.
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
