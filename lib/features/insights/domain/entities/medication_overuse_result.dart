import 'package:meta/meta.dart';

/// How close one month is to the medication-overuse threshold.
enum MedicationOveruseRisk {
  /// Comfortably under. Nothing is said, because a counter that speaks every month teaches the user to stop reading it.
  none,

  /// Near enough that the month can still be steered.
  approaching,

  /// At or over the threshold. Said plainly, and never sold.
  atRisk,
}

/// One month's intake days.
@immutable
class MonthlyIntakeDays {
  const MonthlyIntakeDays({required this.month, required this.days});

  /// The first of the month, local.
  final DateTime month;

  /// Distinct local days on which any acute medication was recorded.
  final int days;
}

/// Whether the user is heading for medication-overuse headache.
@immutable
class MedicationOveruseResult {
  const MedicationOveruseResult({
    required this.months,
    required this.thresholdDays,
    required this.warnAtDays,
    required this.sustainedMonths,
  });

  /// Oldest first, one entry per month in the window.
  final List<MonthlyIntakeDays> months;

  /// Intake days per month at which ICHD-3 puts triptans, ergots, opioids and combination analgesics, and multiple classes taken together.
  final int thresholdDays;

  /// Where the count starts speaking, below the threshold — a warning that only arrives on the day it is crossed is a report, not a warning.
  final int warnAtDays;

  /// Consecutive months that turn a run of heavy months into the pattern ICHD-3 describes.
  final int sustainedMonths;

  MonthlyIntakeDays? get currentMonth => months.isEmpty ? null : months.last;

  int get currentMonthDays => currentMonth?.days ?? 0;

  /// Months at or over the threshold, counting back from the current one and stopping at the first that is under.
  int get consecutiveMonthsAtRisk {
    int run = 0;

    for (final MonthlyIntakeDays month in months.reversed) {
      if (month.days < thresholdDays) break;
      run++;
    }

    return run;
  }

  /// The run is long enough to be the pattern rather than a bad stretch.
  bool get isSustained => consecutiveMonthsAtRisk >= sustainedMonths;

  MedicationOveruseRisk get risk {
    if (currentMonthDays >= thresholdDays) return MedicationOveruseRisk.atRisk;
    if (currentMonthDays >= warnAtDays) {
      return MedicationOveruseRisk.approaching;
    }

    return MedicationOveruseRisk.none;
  }
}
