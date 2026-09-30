import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/analytics/app_analytics.dart';
import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/enums/daily_factor.dart';
import '../../providers.dart';

/// What the check-in screen has been told so far. Every field is optional: a check-in nobody can leave half-done is one they stop opening.
class DailyCheckInState {
  const DailyCheckInState({
    this.sleepQuality,
    this.stressLevel,
    this.factors = const <DailyFactor>{},
    this.isSaving = false,
  });

  final int? sleepQuality;
  final int? stressLevel;
  final Set<DailyFactor> factors;
  final bool isSaving;

  /// Whether there is anything to write. An untouched screen must not overwrite a day the user already answered.
  bool get hasAnswer =>
      sleepQuality != null || stressLevel != null || factors.isNotEmpty;

  DailyCheckInState copyWith({
    int? sleepQuality,
    int? stressLevel,
    Set<DailyFactor>? factors,
    bool? isSaving,
  }) => DailyCheckInState(
    sleepQuality: sleepQuality ?? this.sleepQuality,
    stressLevel: stressLevel ?? this.stressLevel,
    factors: factors ?? this.factors,
    isSaving: isSaving ?? this.isSaving,
  );
}

/// Owns the check-in for one day: what has been picked, and the single write that ends it.
class DailyLogController extends Notifier<DailyCheckInState> {
  @override
  DailyCheckInState build() => const DailyCheckInState();

  /// Fills the screen from the day's existing row, so re-opening a check-in edits it instead of starting again.
  void load(DailyLog? existing) {
    if (existing == null) {
      state = const DailyCheckInState();
      return;
    }
    state = DailyCheckInState(
      sleepQuality: existing.sleepQuality,
      stressLevel: existing.stressLevel,
      factors: existing.factors.toSet(),
    );
  }

  /// Tapping the rating already showing takes it back — the only way to unsay an answer on a screen with no clear button.
  void pickSleepQuality(int rating) {
    state = DailyCheckInState(
      sleepQuality: state.sleepQuality == rating ? null : rating,
      stressLevel: state.stressLevel,
      factors: state.factors,
    );
  }

  /// Sets the sleep answer without the toggle [pickSleepQuality] applies: the dashboard card has already said which one was tapped, and arriving on the screen must not take it back.
  void presetSleepQuality(int rating) {
    state = state.copyWith(sleepQuality: rating);
  }

  void pickStressLevel(int rating) {
    state = DailyCheckInState(
      sleepQuality: state.sleepQuality,
      stressLevel: state.stressLevel == rating ? null : rating,
      factors: state.factors,
    );
  }

  void toggleFactor(DailyFactor factor) {
    final Set<DailyFactor> next = <DailyFactor>{...state.factors};

    next.contains(factor) ? next.remove(factor) : next.add(factor);
    state = state.copyWith(factors: next);
  }

  /// Writes the day. The step count is read first because it belongs to the row, and a Health that will not answer costs a number rather than the save.
  Future<void> save(DateTime day) async {
    SdLogger.action(LogTagConstant.dailyLog, 'Save daily check-in', {
      'day': day.toIso8601String(),
      'sleepQuality': state.sleepQuality,
      'stressLevel': state.stressLevel,
      'factors': <String>[for (final DailyFactor f in state.factors) f.name],
    });
    state = state.copyWith(isSaving: true);
    try {
      final int? steps = await ref.read(dailyStepReaderProvider).stepsFor(day);

      await ref
          .read(dailyLogRepositoryProvider)
          .save(
            DailyLog(
              day: day,
              sleepQuality: state.sleepQuality,
              stressLevel: state.stressLevel,
              factors: state.factors.toList(),
              steps: steps,
            ),
          );
      AppAnalytics.logDailyCheckInSaved();
      // The nudge asks about an open day, so answering one moves it to the next.
      unawaited(
        ref.read(checkInReminderControllerProvider.notifier).reschedule(),
      );
      SdLogger.info(LogTagConstant.dailyLog, 'Daily check-in saved', {
        'day': day.toIso8601String(),
        'steps': steps,
      });
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.dailyLog,
        'Saving the daily check-in failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'day': day.toIso8601String()},
      );
      rethrow;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}
