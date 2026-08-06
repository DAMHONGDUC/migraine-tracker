import 'package:drift/drift.dart';

/// Ids of rows the user deleted, kept only until the server is told. One
/// table for every kind of record rather than one per feature: a tombstone
/// carries no data of its own, so three copies of the same two columns would
/// be three chances to disagree.
///
/// Holds nothing but an opaque id — the row itself is really gone the moment
/// the user deletes it, so no name, dose or note outlives a delete.
@DataClassName('SyncTombstoneRow')
class SyncTombstones extends Table {
  /// Which kind of record this id belonged to. See `SyncCollection`.
  TextColumn get collection => text()();

  TextColumn get id => text()();

  /// Doubles as the row's `updatedAt` when a deletion races an edit made on
  /// another device — latest wins either way.
  DateTimeColumn get deletedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {collection, id};
}
