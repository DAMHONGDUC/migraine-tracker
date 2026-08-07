import 'package:migraine_tracker/features/alerts/domain/repositories/alert_registration_repository.dart';

/// Records what the wipe asked of the alert registration, so a test can prove
/// the push token was given up — the one thing that could still reach a user
/// after they deleted everything.
class RecordingAlertRegistration implements AlertRegistrationRepository {
  int forgetCalls = 0;
  int unregisterCalls = 0;

  @override
  Future<void> register({required double thresholdHpa}) async {}

  @override
  Future<void> updateThreshold(double thresholdHpa) async {}

  @override
  Future<void> unregister() async => unregisterCalls++;

  @override
  Future<void> forgetRegistration() async => forgetCalls++;
}
