import 'package:drift/drift.dart';

/// Ids of rows the user deleted, kept only until the server is told.
@DataClassName('SyncTombstoneRow')
class SyncTombstones extends Table {
  /// Which kind of record this id belonged to. See `SyncCollection`.
  TextColumn get collection => text()();

  TextColumn get id => text()();

  /// Doubles as the row's `updatedAt` when a deletion races an edit made on another device — latest wins either way.
  DateTimeColumn get deletedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {collection, id};
}
