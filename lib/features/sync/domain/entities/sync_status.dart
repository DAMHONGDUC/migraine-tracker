import 'package:meta/meta.dart';

enum SyncPhase { idle, syncing, failed }

/// What the UI is allowed to know about sync. Nothing is ever gated on it, and nothing steers it — the only reader is History's first-pull empty state (hard rule 12).
@immutable
class SyncStatus {
  const SyncStatus({this.phase = SyncPhase.idle, this.isFirstPull = false});

  final SyncPhase phase;

  /// True while the very first pull for this account is in flight, when local history is empty because it has not arrived yet — not because there is none.
  final bool isFirstPull;

  bool get isSyncing => phase == SyncPhase.syncing;

  SyncStatus copyWith({SyncPhase? phase, bool? isFirstPull}) => SyncStatus(
    phase: phase ?? this.phase,
    isFirstPull: isFirstPull ?? this.isFirstPull,
  );
}
