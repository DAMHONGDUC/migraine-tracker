import 'package:meta/meta.dart';

enum SyncPhase { idle, syncing, failed }

/// What the UI is allowed to know about sync. Nothing is ever gated on it — it drives an indicator, never a block (hard rule 12).
@immutable
class SyncStatus {
  const SyncStatus({
    this.phase = SyncPhase.idle,
    this.isFirstPull = false,
    this.progress = 0,
    this.lastSyncedAt,
  });

  final SyncPhase phase;

  /// How far the pass in flight has got, 0 to 1. Only meaningful while [isSyncing].
  final double progress;

  /// [progress] as whole percent, which is all the UI ever shows.
  int get percent => (progress * 100).round();

  /// True while the very first pull for this account is in flight, when local history is empty because it has not arrived yet — not because there is none.
  final bool isFirstPull;

  final DateTime? lastSyncedAt;

  bool get isSyncing => phase == SyncPhase.syncing;

  SyncStatus copyWith({
    SyncPhase? phase,
    bool? isFirstPull,
    double? progress,
    DateTime? lastSyncedAt,
  }) => SyncStatus(
    phase: phase ?? this.phase,
    isFirstPull: isFirstPull ?? this.isFirstPull,
    progress: progress ?? this.progress,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );
}
