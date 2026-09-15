import '../entities/cycle_day.dart';
import '../entities/sleep_night.dart';
import '../entities/step_day.dart';
import '../entities/step_hour.dart';
import '../enums/health_data_kind.dart';

/// Read-only access to the platform health store (Apple HealthKit).
abstract interface class HealthRepository {
  /// Whether this device can serve health data at all.
  bool get isAvailable;

  /// Shows Apple's HealthKit sheet for one [kind] and resolves once it is answered.
  Future<bool> requestAuthorization(HealthDataKind kind);

  /// Sleep between [from] and [to] (local time), grouped into one entry per night, oldest first.
  Future<List<SleepNight>> sleepNights({
    required DateTime from,
    required DateTime to,
  });

  /// Steps between [from] and [to] (local time), grouped into one entry per day, oldest first.
  Future<List<StepDay>> stepDays({
    required DateTime from,
    required DateTime to,
  });

  /// Menstruation between [from] and [to] (local time), one entry per day, oldest first. Never stored — it is read where it is shown and nowhere else.
  Future<List<CycleDay>> cycleDays({
    required DateTime from,
    required DateTime to,
  });

  /// Steps between [from] and [to] (local time), grouped into one entry per hour, oldest first.
  Future<List<StepHour>> stepHours({
    required DateTime from,
    required DateTime to,
  });
}
