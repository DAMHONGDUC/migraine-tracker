import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/db/database_provider.dart';
import '../health/providers.dart';
import 'data/repositories/drift_daily_log_repository.dart';
import 'domain/entities/daily_log.dart';
import 'domain/repositories/daily_log_repository.dart';
import 'domain/services/daily_step_reader.dart';
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

/// Whether the dashboard still has to ask. False while the row exists but holds only a step count Health filled in.
final isTodayCheckedInProvider = Provider<bool>(
  (ref) => ref.watch(todayDailyLogProvider).value?.isAnswered ?? false,
);

/// How many days the user has actually answered — what the trigger map counts before it will render.
final answeredDailyLogCountProvider = FutureProvider<int>(
  (ref) => ref.watch(dailyLogRepositoryProvider).answeredCount(),
);

final dailyLogControllerProvider =
    NotifierProvider<DailyLogController, DailyCheckInState>(
      DailyLogController.new,
    );
