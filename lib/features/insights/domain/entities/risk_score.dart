import 'package:meta/meta.dart';

/// What the risk score is built out of. Every one of them is a number the app already holds — there is no model here, and no signal the user cannot check.
enum RiskSignal { pressureDrop, cycleWindow, sleepDebt, recentFrequency }

/// How far up the scale a day sits.
enum RiskBand { low, moderate, high }

/// One signal's contribution to one day, and the reading behind it.
@immutable
class RiskContribution {
  const RiskContribution({
    required this.signal,
    required this.points,
    required this.maxPoints,
    required this.isAvailable,
    this.dropHpa,
    this.dayInCycle,
    this.sleepDebtMinutes,
    this.recentAttacks,
  });

  /// The signal could not be read at all — no forecast, no cycle, no night. It scores nothing AND is left out of the total's denominator.
  const RiskContribution.unavailable(this.signal, this.maxPoints)
    : points = 0,
      isAvailable = false,
      dropHpa = null,
      dayInCycle = null,
      sleepDebtMinutes = null,
      recentAttacks = null;

  final RiskSignal signal;
  final double points;
  final int maxPoints;
  final bool isAvailable;

  /// The reading this signal scored on, so the card can show its working. One of these is set per signal; the rest stay null.
  final double? dropHpa;
  final int? dayInCycle;
  final int? sleepDebtMinutes;
  final int? recentAttacks;
}

/// One day of the forecast.
@immutable
class DailyRisk {
  DailyRisk({required DateTime day, required this.contributions})
    : day = DateTime(day.year, day.month, day.day);

  final DateTime day;
  final List<RiskContribution> contributions;

  double get _points => contributions.fold<double>(
    0,
    (double sum, RiskContribution c) => sum + c.points,
  );

  /// The weight of the signals that could actually be read. Zero when none could.
  int get availablePoints => contributions
      .where((RiskContribution c) => c.isAvailable)
      .fold<int>(0, (int sum, RiskContribution c) => sum + c.maxPoints);

  /// 0–100, out of what was readable rather than out of a fixed 100.
  ///
  /// A day missing its sleep reading would otherwise score low for the reason
  /// that nothing was known about it, which is the one thing a risk score must
  /// never do. The card names every signal it could not read.
  int get score =>
      availablePoints == 0 ? 0 : ((_points / availablePoints) * 100).round();

  RiskBand get band => switch (score) {
    < 30 => RiskBand.low,
    < 60 => RiskBand.moderate,
    _ => RiskBand.high,
  };

  /// Every signal that had nothing to read, so the card can say so instead of implying the day is quiet.
  List<RiskSignal> get missing => <RiskSignal>[
    for (final RiskContribution c in contributions)
      if (!c.isAvailable) c.signal,
  ];
}

/// The week ahead, today first.
@immutable
class RiskForecast {
  const RiskForecast({
    required this.days,
    required this.historyDays,
    required this.requiredHistoryDays,
  });

  final List<DailyRisk> days;

  /// How much history the frequency baseline has behind it, and how much it wants.
  final int historyDays;
  final int requiredHistoryDays;

  /// A score is only worth showing once the day it compares against means something.
  bool get isReady =>
      days.isNotEmpty &&
      historyDays >= requiredHistoryDays &&
      days.first.availablePoints > 0;

  DailyRisk? get today => days.isEmpty ? null : days.first;
}
