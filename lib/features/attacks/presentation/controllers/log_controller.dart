import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/attack.dart';
import '../../domain/enums/head_location.dart';
import '../../providers.dart';

/// Steps of the sacred 3-tap flow.
enum LogStep { intensity, location, medication, saved }

@immutable
class LogFlowState {
  const LogFlowState({
    this.step = LogStep.intensity,
    this.intensity,
    this.location,
    this.savedId,
  });

  final LogStep step;
  final int? intensity;
  final HeadLocation? location;
  final String? savedId;

  LogFlowState _copyWith({
    LogStep? step,
    int? intensity,
    HeadLocation? location,
    String? savedId,
  }) => LogFlowState(
    step: step ?? this.step,
    intensity: intensity ?? this.intensity,
    location: location ?? this.location,
    savedId: savedId ?? this.savedId,
  );
}

/// Owns the 3-tap flow state machine and persistence. Widgets only render
/// this state and call these methods — no business logic in the UI layer.
class LogController extends Notifier<LogFlowState> {
  static const _uuid = Uuid();

  @override
  LogFlowState build() => const LogFlowState();

  void selectIntensity(int value) {
    state = state._copyWith(intensity: value, step: LogStep.location);
  }

  void selectLocation(HeadLocation location) {
    state = state._copyWith(location: location, step: LogStep.medication);
  }

  /// Third tap: persists the attack and moves to the saved confirmation.
  /// Weather is attached best-effort; logging never waits for the network.
  Future<void> save(String? medicationName) async {
    final attack = Attack(
      id: _uuid.v4(),
      startedAt: DateTime.now().toUtc(),
      intensity: state.intensity!,
      location: state.location!,
      medicationName: medicationName,
    );
    await ref.read(attackRepositoryProvider).insert(attack);
    unawaited(ref.read(weatherAttachServiceProvider).onAttackLogged(attack));
    state = state._copyWith(savedId: attack.id, step: LogStep.saved);
  }

  /// Steps back one screen so a mis-tap can be corrected.
  void back() {
    state = switch (state.step) {
      LogStep.location => state._copyWith(step: LogStep.intensity),
      LogStep.medication => state._copyWith(step: LogStep.location),
      _ => state,
    };
  }

  void reset() => state = const LogFlowState();
}

final logControllerProvider = NotifierProvider<LogController, LogFlowState>(
  LogController.new,
);
