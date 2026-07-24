import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../attacks/providers.dart';
import 'domain/entities/week_summary.dart';
import 'domain/services/week_summary_calculator.dart';

/// This-week-vs-last-week summary for the dashboard card. Recomputes whenever
/// the attack stream emits; defaults to an empty week while the stream loads.
final weekSummaryProvider = Provider<WeekSummary>((ref) {
  const calculator = WeekSummaryCalculator();
  final attacks = ref.watch(attacksStreamProvider).value ?? const [];
  return calculator.compute(attacks, now: DateTime.now());
});
