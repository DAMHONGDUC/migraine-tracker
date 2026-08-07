import 'package:meta/meta.dart';

/// What one sync pass actually moved.
@immutable
class SyncOutcome {
  const SyncOutcome({this.pushed = 0, this.pulled = 0, this.unreadable = 0});

  /// Local changes the server accepted.
  final int pushed;

  /// Remote changes applied on top of local data.
  final int pulled;

  /// Records that could not be decrypted or parsed and were skipped. Always
  /// worth reporting: it means data is up there that this build cannot read.
  final int unreadable;
}
