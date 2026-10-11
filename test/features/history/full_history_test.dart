import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/attacks/presentation/screens/attack_detail_screen/attack_detail_screen.dart';
import 'package:migraine_tracker/features/dashboard/presentation/screens/dashboard_screen/dashboard_screen.dart';
import 'package:migraine_tracker/features/history/presentation/widgets/attack_tile.dart';
import 'package:migraine_tracker/features/settings/providers.dart';

import '../../helpers/pump_app.dart';

/// The whole history is free: an attack from months ago reads and opens like
/// yesterday's (`docs/PREMIUM_RULES.md`). There was a 90-day window here.
void main() {
  /// One recent attack and one from four months ago.
  Future<void> seed(PumpedApp app) async {
    final DriftAttackRepository repo = DriftAttackRepository(app.db);

    await repo.insert(
      Attack(
        id: 'recent',
        startedAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
        intensity: 5,
        regions: const <HeadRegion>[HeadRegion.templeL],
      ),
    );
    await repo.insert(
      Attack(
        id: 'old',
        startedAt: DateTime.now().toUtc().subtract(
          const Duration(days: 120),
        ),
        intensity: 7,
        regions: const <HeadRegion>[HeadRegion.templeR],
      ),
    );
  }

  Future<PumpedApp> openSeededHistory(WidgetTester tester) async {
    final PumpedApp app = await pumpApp(tester);
    await seed(app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await openHistory(tester);

    return app;
  }

  testWidgets('a free user gets every row, none of them tagged', (
    tester,
  ) async {
    await openSeededHistory(tester);

    expect(find.byType(AttackTile), findsNWidgets(2));
    expect(find.text('Premium required'), findsNothing);
    expect(find.textContaining('are locked'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('the old attack opens like any other', (tester) async {
    await openSeededHistory(tester);

    await tester.tap(find.text('Right temple'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AttackDetailScreen), findsOneWidget);

    await finishTest(tester);
  });

  // The seed is the only data most screens are ever developed against, so
  // "seed then look at History" is the path that actually has to work.
  testWidgets('the older rows the dev seed writes are readable', (tester) async {
    await pumpApp(tester);
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(DashboardScreen)),
    );

    await container.read(devSeedServiceProvider).seed();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await openHistory(tester);

    // The older rows are last in a newest-first lazy list: drag to the end.
    for (int i = 0; i < 20; i++) {
      await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -200));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump();

    expect(find.text('Premium required'), findsNothing);
    expect(find.byType(AttackTile), findsWidgets);

    await finishTest(tester);
  });
}
