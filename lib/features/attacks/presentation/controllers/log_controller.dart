import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/attack.dart';
import '../../domain/enums/head_location.dart';
import '../../providers.dart';

/// Steps of the sacred flow: pick a value, then confirm with Next/Done.
enum LogStep { intensity, location, medication, saved }

@immutable
class LogFlowState {
  const LogFlowState({
    this.step = LogStep.intensity,
    this.intensity,
    this.location,
    this.savedId,
    this.hasDraft = false,
    this.draft,
  });

  final LogStep step;
  final int? intensity;
  final HeadLocation? location;
  final String? savedId;

  /// Whether the active step currently has a pick worth confirming — arms
  /// the app bar's Next/Done button. Kept separate from [draft] because a
  /// valid medication pick can itself be null ("No medication").
  final bool hasDraft;

  /// The active step's picked-but-not-yet-confirmed value: an `int`
  /// (intensity), a [HeadLocation], or a `String?` (medication name).
  final Object? draft;
}

/// Owns the flow's state machine and persistence. Widgets only render this
/// state and call these methods — no business logic in the UI layer.
class LogController extends Notifier<LogFlowState> {
  static const _uuid = Uuid();

  @override
  LogFlowState build() => const LogFlowState();

  /// First tap: intensity advances immediately, no confirm step — it's the
  /// fastest way into the flow, mid-attack.
  void selectIntensity(int value) {
    state = LogFlowState(step: LogStep.location, intensity: value);
  }

  /// Called by the location/medication step whenever the user picks or
  /// changes a value. Only arms the app bar's Next button — doesn't
  /// advance the flow.
  void updateDraft(Object? value) {
    state = LogFlowState(
      step: state.step,
      intensity: state.intensity,
      location: state.location,
      savedId: state.savedId,
      hasDraft: true,
      draft: value,
    );
  }

  /// App bar Next: commits the active step's draft and advances. On the
  /// medication step this also persists the attack.
  Future<void> confirmStep() async {
    switch (state.step) {
      case LogStep.location:
        state = LogFlowState(
          step: LogStep.medication,
          intensity: state.intensity,
          location: state.draft! as HeadLocation,
        );
      case LogStep.medication:
        await _save(state.draft as String?);
      case LogStep.intensity:
      case LogStep.saved:
        break;
    }
  }

  /// Persists the attack and moves to the saved confirmation. Weather is
  /// attached best-effort; logging never waits for the network.
  Future<void> _save(String? medicationName) async {
    final attack = Attack(
      id: _uuid.v4(),
      startedAt: DateTime.now().toUtc(),
      intensity: state.intensity!,
      location: state.location!,
      medicationName: medicationName,
    );

    try {
      await ref.read(attackRepositoryProvider).insert(attack);
      AppLogger.action('Attack logged', {
        'intensity': attack.intensity,
        'location': attack.location.name,
        'medication': medicationName,
      });
      unawaited(ref.read(weatherAttachServiceProvider).onAttackLogged(attack));
      state = LogFlowState(savedId: attack.id, step: LogStep.saved);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Attack log failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Steps back one screen so a mis-tap can be corrected. The previous
  /// step's committed value is kept both on record and pre-filled as the
  /// draft, so Next is armed immediately and the old pick shows selected.
  void back() {
    state = switch (state.step) {
      LogStep.location => LogFlowState(
        step: LogStep.intensity,
        intensity: state.intensity,
        draft: state.intensity,
        hasDraft: state.intensity != null,
      ),
      LogStep.medication => LogFlowState(
        step: LogStep.location,
        intensity: state.intensity,
        location: state.location,
        draft: state.location,
        hasDraft: state.location != null,
      ),
      _ => state,
    };
  }

  void reset() => state = const LogFlowState();
}
