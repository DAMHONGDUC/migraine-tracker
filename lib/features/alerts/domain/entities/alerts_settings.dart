import 'package:meta/meta.dart';

@immutable
class AlertsSettings {
  const AlertsSettings({required this.enabled, required this.thresholdHpa});

  final bool enabled;
  final double thresholdHpa;

  AlertsSettings copyWith({bool? enabled, double? thresholdHpa}) =>
      AlertsSettings(
        enabled: enabled ?? this.enabled,
        thresholdHpa: thresholdHpa ?? this.thresholdHpa,
      );
}
