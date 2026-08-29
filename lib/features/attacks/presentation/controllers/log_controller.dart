import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:system_design/common.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../../review/providers.dart';
import '../../../sync/domain/enums/sync_trigger.dart';
import '../../../sync/providers.dart';
import '../../domain/entities/attack.dart';
import '../../domain/enums/exertion_level.dart';
import '../../domain/enums/head_region.dart';
import '../../providers.dart';

/// Steps of the sacred flow: pick a value, then confirm with Next/Done.
enum LogStep { intensity, location, medication, exertion, saved }

@immutable
class LogFlowState {
  const LogFlowState({
    this.step = LogStep.intensity,
    this.intensity,
    this.regions,
    this.medicationName,
    this.savedId,
    this.hasDraft = false,
    this.draft,
  });

  final LogStep step;
  final int? intensity;
  /// Every area confirmed on the location step.
  final List<HeadRegion>? regions;

  /// Committed on the medication step, held until the save at the end of the exertion step. Null is a real answer here ("No medication").
  final String? medicationName;

  final String? savedId;

  /// Whether the active step currently has a pick worth confirming — arms the app bar's Next/Done button.
  final bool hasDraft;

  /// The active step's picked-but-not-yet-confirmed value: an `int` (intensity), a `List<HeadRegion>`, a `String?` (medication name) or an [ExertionLevel].
  final Object? draft;
}

/// Owns the flow's state machine and persistence. Widgets only render this state and call these methods — no business logic in the UI layer.
class LogController extends Notifier<LogFlowState> {
  static const _uuid = Uuid();

  @override
  LogFlowState build() => const LogFlowState();

  /// First tap: intensity advances immediately, no confirm step — it's the fastest way into the flow, mid-attack.
  void selectIntensity(int value) {
    state = LogFlowState(step: LogStep.location, intensity: value);
    // Funnel only — the step reached, never the value picked (health data).
    AppAnalytics.logLogFlowStep(LogStep.location.name);
  }

  /// Called by a step whenever the user picks or changes a value. Only arms the app bar's Next button — doesn't advance the flow.
  void updateDraft(Object? value) {
    state = LogFlowState(
      step: state.step,
      intensity: state.intensity,
      regions: state.regions,
      medicationName: state.medicationName,
      savedId: state.savedId,
      hasDraft: true,
      draft: value,
    );
  }

  /// App bar Next: commits the active step's draft and advances. On the exertion step this also persists the attack.
  Future<void> confirmStep() async {
    switch (state.step) {
      case LogStep.location:
        state = LogFlowState(
          step: LogStep.medication,
          intensity: state.intensity,
          regions: state.draft! as List<HeadRegion>,
          // Defaults to "No medication": the common answer costs no tap, and Next is armed on arrival rather than after a pick.
          hasDraft: true,
        );
        AppAnalytics.logLogFlowStep(LogStep.medication.name);
      case LogStep.medication:
        state = LogFlowState(
          step: LogStep.exertion,
          intensity: state.intensity,
          regions: state.regions,
          medicationName: state.draft as String?,
          // Same idea: "None" is the common answer and the step's default.
          hasDraft: true,
          draft: ExertionLevel.none,
        );
        AppAnalytics.logLogFlowStep(LogStep.exertion.name);
      case LogStep.exertion:
        // Never blocks: the step arrives on [ExertionLevel.none], so Next works before the user touches anything (hard rule 5).
        await _save(state.medicationName, state.draft as ExertionLevel?);
      case LogStep.intensity:
      case LogStep.saved:
        break;
    }
  }

  /// Persists the attack and moves to the saved confirmation. Weather is attached best-effort; logging never waits for the network.
  Future<void> _save(
    String? medicationName,
    ExertionLevel? exertionLevel,
  ) async {
    final attack = Attack(
      id: _uuid.v4(),
      startedAt: DateTime.now().toUtc(),
      intensity: state.intensity!,
      regions: state.regions!,
      medicationName: medicationName,
      exertionLevel: exertionLevel,
    );

    try {
      await ref.read(attackRepositoryProvider).insert(attack);
      SdLogger.action(LogTagConstant.attackLog, 'Attack logged', {
        'intensity': attack.intensity,
        'regions': attack.regions.length,
        'medication': medicationName,
        'exertion': exertionLevel?.name,
      });
      AppAnalytics.logAttackLogged();
      AppAnalytics.logLogFlowStep(LogStep.saved.name);
      unawaited(ref.read(weatherAttachServiceProvider).onAttackLogged(attack));
      // Local read, but still unawaited: HealthKit is another process, and nothing in the log flow waits (hard rule 4).
      unawaited(ref.read(stepAttachServiceProvider).onAttackLogged(attack));
      // Same best-effort shape: the attack is already saved, so a failure here leaves it pending for the next sync (hard rule 4).
      unawaited(
        ref
            .read(syncControllerProvider.notifier)
            .sync(trigger: SyncTrigger.record),
      );
      // Only a moment when a pressure alert came first — the controller decides that.
      unawaited(
        ref
            .read(reviewPromptControllerProvider)
            .onAttackLogged(attack.startedAt),
      );
      state = LogFlowState(savedId: attack.id, step: LogStep.saved);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.attackLog,
        'Attack log failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Steps back one screen so a mis-tap can be corrected.
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
        regions: state.regions,
        draft: state.regions,
        hasDraft: state.regions != null,
      ),
      // Medication was confirmed to get here, and "No medication" is a valid confirmed pick — so Next is armed even though the draft is null.
      LogStep.exertion => LogFlowState(
        step: LogStep.medication,
        intensity: state.intensity,
        regions: state.regions,
        medicationName: state.medicationName,
        draft: state.medicationName,
        hasDraft: true,
      ),
      _ => state,
    };
  }

  void reset() => state = const LogFlowState();
}
