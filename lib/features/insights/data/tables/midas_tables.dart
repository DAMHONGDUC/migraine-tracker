import 'package:drift/drift.dart';

/// One row per completed MIDAS questionnaire.
@DataClassName('MidasRow')
class MidasEntries extends Table {
  TextColumn get id => text()();

  /// When the questionnaire was answered, UTC. The answers are about the three months before it.
  DateTimeColumn get takenAt => dateTime()();

  IntColumn get missedWorkDays => integer()();
  IntColumn get reducedWorkDays => integer()();
  IntColumn get missedHouseholdDays => integer()();
  IntColumn get reducedHouseholdDays => integer()();
  IntColumn get missedSocialDays => integer()();

  /// Wall clock of the last local mutation, used only to settle which of two devices' versions wins.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  /// Bumped on every local mutation.
  IntColumn get revision => integer().withDefault(const Constant(0))();

  /// The [revision] the server confirmed.
  IntColumn get syncedRevision => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
