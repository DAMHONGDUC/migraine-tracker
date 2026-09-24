import 'package:meta/meta.dart';

enum SyncPhase { idle, syncing, failed }

/// What the UI is allowed to know about sync. Nothing is ever gated on it, and nothing steers it — History's first-pull empty state and the Settings sync card read it (hard rule 12).
@immutable
class SyncStatus {
  const SyncStatus({
    this.phase = SyncPhase.idle,
    this.isFirstPull = false,
    this.done = 0,
    this.total = 0,
    this.pending,
  });

  final SyncPhase phase;

  /// True while the very first pull for this account is in flight, when local history is empty because it has not arrived yet — not because there is none.
  final bool isFirstPull;

  /// Records the running pass or push has moved so far. Zero outside one.
  final int done;

  /// Records the running pass or push knows it has to move. Grows during a pass as each collection's pull lands.
  final int total;

  /// Records still owed to the server, counted after every pass and push. Null until the first count.
  final int? pending;

  bool get isSyncing => phase == SyncPhase.syncing;

  /// 0–1 for a bar, or null while there is nothing to measure yet.
  double? get progress => total == 0 ? null : (done / total).clamp(0, 1);

  SyncStatus copyWith({
    SyncPhase? phase,
    bool? isFirstPull,
    int? done,
    int? total,
    int? pending,
  }) => SyncStatus(
    phase: phase ?? this.phase,
    isFirstPull: isFirstPull ?? this.isFirstPull,
    done: done ?? this.done,
    total: total ?? this.total,
    pending: pending ?? this.pending,
  );
}
