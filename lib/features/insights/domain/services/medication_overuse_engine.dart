import '../../../attacks/domain/entities/attack.dart';
import '../entities/medication_overuse_result.dart';

/// Medication-overuse headache: is the treatment becoming the cause?
///
/// The one analysis in the app that exists to tell the user something they do
/// not want to hear. Acute medication taken often enough starts producing the
/// headaches it is taken for, and nobody counts their own intake days — the
/// app already holds every one of them.
///
/// Pure Dart and deterministic. It reads [Attack.medicationName] and
/// [Attack.startedAt] only, so it needs no new field and no new question.
class MedicationOveruseEngine {
  const MedicationOveruseEngine({
    this.months = defaultMonths,
    this.thresholdDays = defaultThresholdDays,
    this.warnAtDays = defaultWarnAtDays,
    this.sustainedMonths = defaultSustainedMonths,
  }) : assert(months > 0, 'months must be positive'),
       assert(warnAtDays > 0, 'warnAtDays must be positive'),
       assert(
         warnAtDays < thresholdDays,
         'warnAtDays must sit below thresholdDays',
       );

  static const int defaultMonths = 6;

  /// ICHD-3 8.2: ten intake days a month is where triptans, ergots, opioids
  /// and combination analgesics sit, and where 8.2.6 puts several classes
  /// taken together. Simple analgesics alone are 15, but the app does not
  /// know which class a medication belongs to, and the safe error here is the
  /// early word rather than the late one — this warns, it does not diagnose.
  static const int defaultThresholdDays = 10;

  /// Two days of warning. A month is steerable at eight and spent at ten.
  static const int defaultWarnAtDays = 8;

  /// ICHD-3 asks for the pattern to hold longer than three months before it
  /// is medication-overuse headache at all.
  static const int defaultSustainedMonths = 3;

  final int months;
  final int thresholdDays;
  final int warnAtDays;
  final int sustainedMonths;

  /// [now] is the caller's clock, so the window ends on the month the user is
  /// in. Local throughout, for the reason every day count here is local: an
  /// evening dose is stored as the next UTC day.
  MedicationOveruseResult analyze(
    List<Attack> attacks, {
    required DateTime now,
  }) {
    final DateTime firstMonth = DateTime(now.year, now.month - (months - 1));
    final Map<DateTime, Set<DateTime>> daysByMonth =
        <DateTime, Set<DateTime>>{};

    for (final Attack attack in attacks) {
      // No medication recorded is not an intake day. "None" is a real answer
      // in the log flow, so this is a fact rather than a gap.
      if ((attack.medicationName?.trim() ?? '').isEmpty) continue;

      final DateTime local = attack.startedAt.toLocal();
      final DateTime month = DateTime(local.year, local.month);

      if (month.isBefore(firstMonth)) continue;

      daysByMonth
          .putIfAbsent(month, () => <DateTime>{})
          .add(DateTime(local.year, local.month, local.day));
    }

    return MedicationOveruseResult(
      months: <MonthlyIntakeDays>[
        for (int i = 0; i < months; i++)
          if (DateTime(firstMonth.year, firstMonth.month + i) case final DateTime
              month)
            MonthlyIntakeDays(
              month: month,
              days: daysByMonth[month]?.length ?? 0,
            ),
      ],
      thresholdDays: thresholdDays,
      warnAtDays: warnAtDays,
      sustainedMonths: sustainedMonths,
    );
  }
}
