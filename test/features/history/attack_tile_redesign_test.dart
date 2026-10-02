import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/history/presentation/widgets/attack_tile.dart';
import 'package:migraine_tracker/features/weather/domain/entities/weather_snapshot.dart';

import '../../helpers/pump_app.dart';

/// The 2026-09-30 history row: the 24h pressure change as a tag, arrow first, and nothing where there is no reading.
void main() {
  Attack attack(String id, int hoursAgo, {double? delta}) {
    final DateTime at = DateTime.now().toUtc().subtract(
      Duration(hours: hoursAgo),
    );

    return Attack(
      id: id,
      startedAt: at,
      intensity: 7,
      regions: const <HeadRegion>[HeadRegion.templeR],
      weather: delta == null
          ? null
          : WeatherSnapshot(
              capturedAt: at,
              pressureHpa: 1006.4,
              pressureDelta24hHpa: delta,
            ),
    );
  }

  testWidgets('each row carries the pressure change, or nothing', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester);
    final DriftAttackRepository repo = DriftAttackRepository(app.db);
    await repo.insert(attack('falling', 2, delta: -6.8));
    await repo.insert(attack('rising', 30, delta: 2.3));
    await repo.insert(attack('steady', 60, delta: -0.6));
    await repo.insert(attack('offline', 90));

    await openHistory(tester);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AttackTile), findsNWidgets(4));
    expect(find.text('↓ 6.8'), findsOneWidget);
    expect(find.text('↑ 2.3'), findsOneWidget);
    expect(find.text('→ 0.6'), findsOneWidget);
    // Three tags for four rows: the attack with no reading has none.
    expect(find.textContaining(RegExp(r'^[↓↑→] ')), findsNWidgets(3));

    await finishTest(tester);
  });
}
