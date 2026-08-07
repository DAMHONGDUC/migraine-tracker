import 'package:meta/meta.dart';

/// One local change still owed to the server: either a record to upload or a
/// deletion to propagate.
@immutable
class SyncRecord<T> {
  const SyncRecord({
    required this.id,
    required this.updatedAt,
    required this.revision,
    this.value,
  });

  /// The row id, which is also the remote document id.
  final String id;

  /// When the change happened. Drives last-write-wins on both sides.
  final DateTime updatedAt;

  /// Which local version this is. Handed back on acknowledgement so an edit
  /// made mid-push is not mistaken for the one that went up. Unused for a
  /// deletion, which is acknowledged by dropping the tombstone.
  final int revision;

  /// Null for a deletion — the row is already gone, only the fact of it still
  /// has to reach the server.
  final T? value;

  bool get isDeleted => value == null;
}
