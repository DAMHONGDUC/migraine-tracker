/// Turns one record into the JSON that gets encrypted, and back.
abstract interface class SyncPayloadCodec<T> {
  String encode(T value);

  /// Throws [FormatException] on anything unreadable. [id] comes from the document, never from the payload — carrying it twice invites drift.
  T decode(String json, {required String id});
}
