import 'package:meta/meta.dart';

enum SyncPhase { idle, syncing, failed }

/// What the UI is allowed to know about sync. Nothing is ever gated on it —
/// it drives an indicator, never a block (hard rule 12).
@immutable
class SyncStatus {
  const SyncStatus({
    this.phase = SyncPhase.idle,
    this.isFirstPull = false,
    this.lastSyncedAt,
  });

  final SyncPhase phase;

  /// True while the very first pull for this account is in flight, when local
  /// history is empty because it has not arrived yet — not because there is
  /// none. Only the history list uses it, to avoid reading as "no data".
  final bool isFirstPull;

  final DateTime? lastSyncedAt;

  bool get isSyncing => phase == SyncPhase.syncing;

  SyncStatus copyWith({
    SyncPhase? phase,
    bool? isFirstPull,
    DateTime? lastSyncedAt,
  }) => SyncStatus(
    phase: phase ?? this.phase,
    isFirstPull: isFirstPull ?? this.isFirstPull,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );
}
