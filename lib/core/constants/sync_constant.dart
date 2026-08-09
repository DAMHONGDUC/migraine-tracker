/// Numbers the sync pass runs by.
final class SyncConstant {
  /// Floor between two automatic passes.
  ///
  /// Launch and resume both fire a sync, so without this ten app opens in ten
  /// minutes were ten whole passes — a callable plus a query and a push per
  /// collection each time, usually to find nothing had changed. Only
  /// `SyncTrigger.automatic` is held back: a manual run is the user asking in
  /// as many words, and a post-log push exists so a fresh attack is not lost
  /// with the phone.
  static const Duration automaticCooldown = Duration(hours: 6);
}
