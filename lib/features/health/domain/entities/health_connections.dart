import 'package:meta/meta.dart';

import '../enums/health_data_kind.dart';

/// Which Apple Health sources the user has connected.
@immutable
class HealthConnections {
  const HealthConnections({required this.sleep, required this.steps});

  const HealthConnections.none() : sleep = false, steps = false;

  final bool sleep;
  final bool steps;

  bool of(HealthDataKind kind) => switch (kind) {
    HealthDataKind.sleep => sleep,
    HealthDataKind.steps => steps,
  };

  HealthConnections withKind(HealthDataKind kind, bool connected) =>
      switch (kind) {
        HealthDataKind.sleep => HealthConnections(
          sleep: connected,
          steps: steps,
        ),
        HealthDataKind.steps => HealthConnections(
          sleep: sleep,
          steps: connected,
        ),
      };

  @override
  bool operator ==(Object other) =>
      other is HealthConnections && other.sleep == sleep && other.steps == steps;

  @override
  int get hashCode => Object.hash(sleep, steps);
}
