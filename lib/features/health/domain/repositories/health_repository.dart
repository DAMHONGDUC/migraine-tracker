import '../entities/sleep_night.dart';
import '../entities/step_day.dart';
import '../enums/health_data_kind.dart';

/// Read-only access to the platform health store (Apple HealthKit).
///
/// Read-only on purpose: BaroEase never writes to Health, so the iOS
/// authorization request asks for share access only and the app ships
/// without `NSHealthUpdateUsageDescription`.
abstract interface class HealthRepository {
  /// Whether this device can serve health data at all. False off iOS: the
  /// Android side of the `health` package talks to Google Fit, which this app
  /// does not use — the sleep feature is iOS-only and its UI hides itself
  /// everywhere else.
  bool get isAvailable;

  /// Shows Apple's HealthKit sheet for one [kind] and resolves once it is
  /// answered. One sheet per source, because sleep and steps are connected
  /// separately — a refusal must cost only the source it was asked about.
  ///
  /// True means the sheet completed, NOT that anything was granted: iOS
  /// deliberately never discloses a *read* denial (that would leak which
  /// conditions a user has by which permissions they refuse). So a true here
  /// can still be followed by [sleepNights]/[stepDays] returning nothing, and
  /// the UI must treat "empty" as "no access or no data" without guessing
  /// which.
  Future<bool> requestAuthorization(HealthDataKind kind);

  /// Sleep between [from] and [to] (local time), grouped into one entry per
  /// night, oldest first.
  ///
  /// Empty when access was refused, when the window holds no samples, or off
  /// iOS. Nights with no samples are absent rather than zero.
  Future<List<SleepNight>> sleepNights({
    required DateTime from,
    required DateTime to,
  });

  /// Steps between [from] and [to] (local time), grouped into one entry per
  /// day, oldest first.
  ///
  /// Empty when access was refused, when the window holds no samples, or off
  /// iOS. Days with no samples are absent rather than zero.
  Future<List<StepDay>> stepDays({required DateTime from, required DateTime to});
}
