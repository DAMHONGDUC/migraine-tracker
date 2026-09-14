import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/constants/daily_log_backfill_constant.dart';
import '../../core/db/database_provider.dart';
import '../../core/utils/date_time_utils.dart';
import '../health/providers.dart';
import 'data/repositories/drift_daily_log_repository.dart';
import 'domain/entities/daily_log.dart';
import 'domain/repositories/daily_log_repository.dart';
import 'domain/services/daily_step_reader.dart';
import 'presentation/controllers/check_in_reminder_controller.dart';
import 'presentation/controllers/daily_log_controller.dart';

final dailyLogRepositoryProvider = Provider<DailyLogRepository>(
  (ref) => DriftDailyLogRepository(ref.watch(databaseProvider)),
);

final dailyStepReaderProvider = Provider<DailyStepReader>(
  (ref) => DailyStepReader(ref.watch(healthRepositoryProvider)),
);

/// Today's row, which is null until the day has been written for the first time.
final todayDailyLogProvider = StreamProvider<DailyLog?>(
  (ref) => ref.watch(dailyLogRepositoryProvider).watchDay(DateTime.now()),
);

/// One day's row, for the check-in opened on a day the user missed. Family-keyed on the day, since the screen may be opened on any of three.
final dailyLogForDayProvider = StreamProvider.family<DailyLog?, DateTime>(
  (ref, DateTime day) => ref.watch(dailyLogRepositoryProvider).watchDay(day),
);

/// The days inside the backfill window that still have no answer, most recent first — what the dashboard offers to catch up on.
final unansweredDaysProvider = FutureProvider<List<DateTime>>((ref) async {
  final DateTime today = DateTime.now();
  final DailyLogRepository repository = ref.watch(dailyLogRepositoryProvider);
  final List<DailyLog> rows = await repository.range(
    today.subtract(Duration(days: DailyLogBackfillConstant.days - 1)),
    today,
  );
  final Set<String> answered = <String>{
    for (final DailyLog log in rows)
      if (log.isAnswered) DateTimeUtils.dayKey(log.day),
  };

  return <DateTime>[
    for (int back = 0; back < DailyLogBackfillConstant.days; back++)
      if (!answered.contains(
        DateTimeUtils.dayKey(today.subtract(Duration(days: back))),
      ))
        DateTime(today.year, today.month, today.day - back),
  ];
});

/// Whether the dashboard still has to ask. False while the row exists but holds only a step count Health filled in.
final isTodayCheckedInProvider = Provider<bool>(
  (ref) => ref.watch(todayDailyLogProvider).value?.isAnswered ?? false,
);

/// Every check-in of the last year, oldest first — what the trigger/protector map and the risk score read.
final recentDailyLogsProvider = FutureProvider<List<DailyLog>>((ref) {
  final DateTime now = DateTime.now();

  return ref
      .watch(dailyLogRepositoryProvider)
      .range(now.subtract(const Duration(days: 365)), now);
});

/// How many days the user has actually answered — what the trigger map counts before it will render.
final answeredDailyLogCountProvider = FutureProvider<int>(
  (ref) => ref.watch(dailyLogRepositoryProvider).answeredCount(),
);

/// The evening nudge's settings, and the one armed notification behind them.
final checkInReminderControllerProvider =
    NotifierProvider<CheckInReminderController, CheckInReminderSettings>(
      CheckInReminderController.new,
    );

final dailyLogControllerProvider =
    NotifierProvider<DailyLogController, DailyCheckInState>(
      DailyLogController.new,
    );
