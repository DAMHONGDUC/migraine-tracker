import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_design/common.dart';

import '../../../../core/constants/log_tag_constant.dart';
import '../../domain/entities/midas_score.dart';
import '../../providers.dart';

/// The five answers as they are being typed, and the running total under them.
class MidasDraft {
  const MidasDraft({this.answers = const <int>[0, 0, 0, 0, 0]});

  /// Q1 to Q5, in the questionnaire's own order.
  final List<int> answers;

  int get score => answers.fold<int>(0, (int sum, int days) => sum + days);

  MidasDraft withAnswer(int index, int days) => MidasDraft(
    answers: <int>[
      for (final (int i, int value) in answers.indexed)
        i == index ? days : value,
    ],
  );
}

/// Owns the questionnaire while it is open, and the single write that ends it.
class MidasController extends Notifier<MidasDraft> {
  @override
  MidasDraft build() => const MidasDraft();

  /// Starts from the last set of answers, so a monthly re-take is an edit of the numbers rather than five fields from zero.
  void loadFrom(MidasEntry? previous) {
    state = previous == null
        ? const MidasDraft()
        : MidasDraft(
            answers: <int>[
              previous.missedWorkDays,
              previous.reducedWorkDays,
              previous.missedHouseholdDays,
              previous.reducedHouseholdDays,
              previous.missedSocialDays,
            ],
          );
  }

  void answer(int index, int days) {
    state = state.withAnswer(index, days < 0 ? 0 : days);
  }

  /// Every save is a new entry, never an edit of the last one: the score is a reading of a three-month window, and two windows are two readings.
  Future<void> save() async {
    SdLogger.action(LogTagConstant.insights, 'Save MIDAS', <String, Object?>{
      'score': state.score,
    });
    try {
      await ref
          .read(midasRepositoryProvider)
          .upsert(
            MidasEntry(
              id: SdId.unique(),
              takenAt: DateTime.now().toUtc(),
              missedWorkDays: state.answers[0],
              reducedWorkDays: state.answers[1],
              missedHouseholdDays: state.answers[2],
              reducedHouseholdDays: state.answers[3],
              missedSocialDays: state.answers[4],
            ),
          );
      SdLogger.info(LogTagConstant.insights, 'MIDAS saved', state.score);
    } catch (error, stackTrace) {
      SdLogger.error(
        LogTagConstant.insights,
        'Saving MIDAS failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'score': state.score},
      );
      rethrow;
    }
  }
}
