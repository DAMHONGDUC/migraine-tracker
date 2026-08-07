/// Turns one record into the JSON that gets encrypted, and back.
///
/// Implementations must refuse anything they cannot rebuild faithfully: a
/// half-read record is worse than a skipped one, because it would overwrite
/// the good local copy. They must also ignore fields they do not know, so
/// adding an optional one never needs a version bump and two builds in the
/// wild can still read each other.
abstract interface class SyncPayloadCodec<T> {
  String encode(T value);

  /// Throws [FormatException] on anything unreadable. [id] comes from the
  /// document, never from the payload — carrying it twice invites drift.
  T decode(String json, {required String id});
}
