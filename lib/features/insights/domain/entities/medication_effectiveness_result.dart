import 'package:meta/meta.dart';

/// One medication's record: how often it was taken, and what it did.
@immutable
class MedicationEffectiveness {
  const MedicationEffectiveness({
    required this.name,
    required this.timesTaken,
    required this.helpedCount,
    required this.partlyCount,
    required this.didNotHelpCount,
    required this.minAnswersForShare,
    this.medianIntensity,
    this.medianDuration,
  });

  final String name;

  /// Attacks this medication was taken for, answered or not.
  final int timesTaken;

  final int helpedCount;
  final int partlyCount;
  final int didNotHelpCount;

  /// Below this many answers the row shows counts, not a percentage.
  final int minAnswersForShare;

  /// Median intensity of the attacks it was taken for. It guards the
  /// comparison: a drug kept for 9/10 attacks cannot be read against one
  /// taken for 4/10 without it.
  final double? medianIntensity;

  /// Median length of those attacks, over the ones whose end was recorded.
  final Duration? medianDuration;

  int get answeredCount => helpedCount + partlyCount + didNotHelpCount;

  /// Taken, but "did it help" never answered.
  int get unansweredCount => timesTaken - answeredCount;

  /// Full and partial relief together — the honest headline, because
  /// "took the edge off" is what most abortives actually do.
  int get anyReliefCount => helpedCount + partlyCount;

  /// Share of answered doses that fully helped, 0–100.
  double get helpedPercent => helpedCount * 100 / answeredCount;

  /// Share of answered doses that helped at all, 0–100.
  double get anyReliefPercent => anyReliefCount * 100 / answeredCount;

  /// A percentage off this few answers is false precision — one dose is 0%
  /// or 100%. "2 of 3" is the same fact without the overclaim.
  bool get isCountOnly => answeredCount < minAnswersForShare;
}

/// Outcome of the medication analysis: which of the user's drugs work?
@immutable
sealed class MedicationEffectivenessResult {
  const MedicationEffectivenessResult({
    required this.answeredAttacks,
    required this.requiredAnswers,
  });

  /// Attacks carrying both a medication and an answer to whether it helped.
  final int answeredAttacks;

  /// Where a row's figure stops moving with every new answer. Not a gate —
  /// the analysis is returned below it too, flagged by [isPreliminary].
  final int requiredAnswers;

  /// The figures are real but still shift a lot per answer, so say so.
  bool get isPreliminary => answeredAttacks < requiredAnswers;
}

/// Nothing was taken, or nothing taken was ever followed up on.
class MedicationEffectivenessInsufficientData
    extends MedicationEffectivenessResult {
  const MedicationEffectivenessInsufficientData({
    required super.answeredAttacks,
    required super.requiredAnswers,
    required this.timesTaken,
  });

  /// Doses recorded with the follow-up question still unanswered. It is the
  /// difference between "you take nothing" and "you never told us if it
  /// worked", and only the second is worth prompting about.
  final int timesTaken;
}

/// The headline: one row per medication, most-used first.
class MedicationEffectivenessInsight extends MedicationEffectivenessResult {
  const MedicationEffectivenessInsight({
    required super.answeredAttacks,
    required super.requiredAnswers,
    required this.medications,
  });

  final List<MedicationEffectiveness> medications;
}
