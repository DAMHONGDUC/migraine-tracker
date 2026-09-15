import 'package:meta/meta.dart';

import '../enums/health_data_kind.dart';

/// Which Apple Health sources the user has connected.
@immutable
class HealthConnections {
  const HealthConnections({
    required this.sleep,
    required this.steps,
    required this.cycle,
  });

  const HealthConnections.none() : sleep = false, steps = false, cycle = false;

  final bool sleep;
  final bool steps;
  final bool cycle;

  bool of(HealthDataKind kind) => switch (kind) {
    HealthDataKind.sleep => sleep,
    HealthDataKind.steps => steps,
    HealthDataKind.cycle => cycle,
  };

  HealthConnections withKind(HealthDataKind kind, bool connected) =>
      switch (kind) {
        HealthDataKind.sleep => HealthConnections(
          sleep: connected,
          steps: steps,
          cycle: cycle,
        ),
        HealthDataKind.steps => HealthConnections(
          sleep: sleep,
          steps: connected,
          cycle: cycle,
        ),
        HealthDataKind.cycle => HealthConnections(
          sleep: sleep,
          steps: steps,
          cycle: connected,
        ),
      };

  @override
  bool operator ==(Object other) =>
      other is HealthConnections &&
      other.sleep == sleep &&
      other.steps == steps &&
      other.cycle == cycle;

  @override
  int get hashCode => Object.hash(sleep, steps, cycle);
}
