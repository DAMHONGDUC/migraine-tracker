/// Numbers the sync pass runs by.
final class SyncConstant {
  /// Floor between two automatic passes.
  static const Duration automaticCooldown = Duration(hours: 6);

  /// How long a local write waits for the writes around it before the push goes out. Long enough that saving a medication and its three reminders is one push, short enough that a record is on the server before the phone can be lost.
  static const Duration writeThroughDebounce = Duration(seconds: 2);
}
