import 'package:drift/drift.dart';

import '../../../../core/db/converters.dart';

/// One row per local calendar day, keyed by the day itself.
///
/// The day is the primary key rather than a UUID so two devices checking in on
/// the same day converge on one row under last-write-wins, instead of syncing
/// two rows that both claim Tuesday. `yyyy-MM-dd` sorts lexicographically in
/// date order, which is what every range query here relies on.
@DataClassName('DailyLogRow')
class DailyLogs extends Table {
  /// The local day as `yyyy-MM-dd` — see `DateTimeUtils.dayKey`.
  TextColumn get id => text()();

  /// 1 (worst) to 5 (best), or null when the user did not answer.
  IntColumn get sleepQuality => integer().nullable()();

  /// 1 (calm) to 5 (worst), or null when the user did not answer.
  IntColumn get stressLevel => integer().nullable()();

  /// The day's factors, JSON-encoded.
  TextColumn get factors => text()
      .map(const DailyFactorListConverter())
      .withDefault(const Constant('[]'))();

  /// Steps that day, from Apple Health. Sleep deliberately has no column beside it: HealthKit is already on-device storage and sleep never leaves it (see `features/health/CLAUDE.md`).
  IntColumn get steps => integer().nullable()();

  /// Wall clock of the last local mutation, used only to settle which of two devices' versions wins.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  /// Bumped on every local mutation.
  IntColumn get revision => integer().withDefault(const Constant(0))();

  /// The [revision] the server confirmed.
  IntColumn get syncedRevision => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
