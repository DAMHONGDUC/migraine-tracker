import 'package:migraine_tracker/features/alerts/domain/enums/alert_registration_error.dart';
import 'package:migraine_tracker/features/alerts/domain/repositories/alert_registration_repository.dart';

/// Records what was asked of the alert registration.
class RecordingAlertRegistration implements AlertRegistrationRepository {
  RecordingAlertRegistration({this.failWith});

  /// When set, every method throws it — the offline/denied path.
  final AlertRegistrationError? failWith;

  final List<double> registeredThresholds = <double>[];
  final List<double> updatedThresholds = <double>[];
  int forgetCalls = 0;
  int unregisterCalls = 0;

  void _failIfAsked() {
    if (failWith != null) throw AlertRegistrationException(failWith!);
  }

  @override
  Future<void> register({required double thresholdHpa}) async {
    _failIfAsked();
    registeredThresholds.add(thresholdHpa);
  }

  @override
  Future<void> updateThreshold(double thresholdHpa) async {
    _failIfAsked();
    updatedThresholds.add(thresholdHpa);
  }

  @override
  Future<void> unregister() async {
    _failIfAsked();
    unregisterCalls++;
  }

  @override
  Future<void> sendTestPush() async {}

  @override
  Future<void> forgetRegistration() async {
    _failIfAsked();
    forgetCalls++;
  }
}
