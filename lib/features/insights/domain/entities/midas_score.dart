import 'package:meta/meta.dart';

/// MIDAS grades, as the questionnaire defines them.
enum MidasGrade { littleOrNone, mild, moderate, severe }

/// One completed MIDAS: the five day-counts, and the score they add up to.
///
/// MIDAS (Migraine Disability Assessment) counts days lost over three months.
/// It ships alone, without HIT-6: HIT-6 is copyrighted by QualityMetric and
/// needs a paid licence, and one score that ships beats two that block review
/// (`docs/rules/DECISIONS.md`).
@immutable
class MidasEntry {
  MidasEntry({
    required this.id,
    required DateTime takenAt,
    required this.missedWorkDays,
    required this.reducedWorkDays,
    required this.missedHouseholdDays,
    required this.reducedHouseholdDays,
    required this.missedSocialDays,
  }) : takenAt = takenAt.toUtc(),
       assert(
         missedWorkDays >= 0 &&
             reducedWorkDays >= 0 &&
             missedHouseholdDays >= 0 &&
             reducedHouseholdDays >= 0 &&
             missedSocialDays >= 0,
         'a MIDAS answer is a count of days and cannot be negative',
       );

  final String id;
  final DateTime takenAt;

  /// Q1: days of work or school missed entirely.
  final int missedWorkDays;

  /// Q2: days at work or school with productivity halved — Q1's days excluded, as the questionnaire instructs.
  final int reducedWorkDays;

  /// Q3: days no household work was done.
  final int missedHouseholdDays;

  /// Q4: days of household work halved, Q3's days excluded.
  final int reducedHouseholdDays;

  /// Q5: days of family, social or leisure activity missed.
  final int missedSocialDays;

  /// The MIDAS score: the five answers added, and nothing else. The two unscored questions (headache days, average pain) are deliberately not asked.
  int get score =>
      missedWorkDays +
      reducedWorkDays +
      missedHouseholdDays +
      reducedHouseholdDays +
      missedSocialDays;

  MidasGrade get grade => gradeOf(score);

  /// The published cut-offs: I 0–5, II 6–10, III 11–20, IV 21+. A static as well, so a running total can be graded before there is an entry to grade.
  static MidasGrade gradeOf(int score) => switch (score) {
    <= 5 => MidasGrade.littleOrNone,
    <= 10 => MidasGrade.mild,
    <= 20 => MidasGrade.moderate,
    _ => MidasGrade.severe,
  };
}
