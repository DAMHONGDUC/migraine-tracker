import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:migraine_tracker/core/constants/premium_limit_constant.dart';
import 'package:migraine_tracker/core/widgets/free_history_banner.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/attacks/presentation/screens/attack_detail_screen/attack_detail_screen.dart';
import 'package:migraine_tracker/features/dashboard/presentation/screens/dashboard_screen/dashboard_screen.dart';
import 'package:migraine_tracker/features/history/presentation/widgets/attack_tile.dart';
import 'package:migraine_tracker/features/history/presentation/widgets/locked_history_sheet.dart';
import 'package:migraine_tracker/features/settings/domain/services/dev_seed_service.dart';
import 'package:migraine_tracker/features/settings/providers.dart';
import 'package:system_design/index.dart';

import '../../helpers/pump_app.dart';

/// A history row behind the free 90-day window: shown, blurred, and tagged.
///
/// It used to be absent, and an absence says nothing — the user could not tell
/// a plan limit from a record that had never been written.
void main() {
  /// One attack inside the window and one behind it.
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
          PremiumLimitConstant.freeHistoryWindow + const Duration(days: 5),
        ),
        intensity: 7,
        regions: const <HeadRegion>[HeadRegion.templeR],
      ),
    );
  }

  Future<PumpedApp> openSeededHistory(
    WidgetTester tester, {
    bool premium = false,
  }) async {
    final PumpedApp app = await pumpApp(tester, premium: premium);
    await seed(app);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await openHistory(tester);

    return app;
  }

  testWidgets('a free user gets both rows, and the old one is tagged', (
    tester,
  ) async {
    await openSeededHistory(tester);

    // Two rows where the window used to leave one.
    expect(find.byType(AttackTile), findsNWidgets(2));
    expect(find.text('Premium required'), findsOneWidget);

    await finishTest(tester);
  });

  // "Attacks before <date> are locked" is a statement about a boundary, so it
  // sits AT the boundary: under the last readable row, over the first blurred
  // one. At the top of the list it was a notice to scroll past.
  testWidgets('the banner sits between the readable and the locked rows', (
    tester,
  ) async {
    await openSeededHistory(tester);

    final double banner = tester.getRect(find.byType(FreeHistoryBanner)).top;
    final double readable = tester.getRect(find.text('Left temple')).top;
    final double locked = tester.getRect(find.text('Premium required')).top;

    expect(banner, greaterThan(readable), reason: 'below the readable row');
    expect(banner, lessThan(locked), reason: 'above the locked row');

    await finishTest(tester);
  });

  // Nothing behind the window is nothing to label.
  testWidgets('premium gets no banner in the list at all', (tester) async {
    await openSeededHistory(tester, premium: true);

    expect(find.byType(FreeHistoryBanner), findsNothing);

    await finishTest(tester);
  });

  testWidgets('tapping the locked row explains instead of opening it', (
    tester,
  ) async {
    await openSeededHistory(tester);

    await tester.tap(find.text('Premium required'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The sheet, not the attack — a locked row leads nowhere while it is locked.
    expect(find.byType(AttackDetailScreen), findsNothing);
    expect(find.text('Older than your free history'), findsOneWidget);
    expect(
      find.textContaining(
        'last ${PremiumLimitConstant.freeHistoryWindow.inDays} days',
      ),
      findsOneWidget,
    );
    // And the way out of it — in the sheet: the banner behind it has its own.
    expect(
      find.descendant(
        of: find.byType(LockedHistorySheet),
        matching: find.widgetWithText(SdButtonV2, 'Unlock'),
      ),
      findsOneWidget,
    );

    await finishTest(tester);
  });

  testWidgets('a readable row still taps straight through', (tester) async {
    await openSeededHistory(tester);

    await tester.tap(find.text('Left temple'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AttackDetailScreen), findsOneWidget);

    await finishTest(tester);
  });

  // The seed is the only data most screens are ever developed against, so
  // "seed then look at History" is the path that actually has to work.
  testWidgets('the dev seed puts blurred rows on the screen', (tester) async {
    await pumpApp(tester);
    // The app's own seeder over the app's own tree, not a stand-in: what broke
    // could have been in the wiring as easily as in the rows.
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(DashboardScreen)),
    );

    await container.read(devSeedServiceProvider).seed();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await openHistory(tester);

    // The locked rows are the OLDEST, so they are last in a newest-first list
    // — and the list is a lazy sliver, so they are not even built until it is
    // scrolled to them. Drag to the end the way a user would.
    for (int i = 0; i < 20; i++) {
      await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -200));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump();

    expect(
      find.text('Premium required'),
      findsNWidgets(DevSeedService.lockedAttackCount),
    );

    await finishTest(tester);
  });

  testWidgets('premium tags nothing and opens the old attack', (tester) async {
    await openSeededHistory(tester, premium: true);

    expect(find.byType(AttackTile), findsNWidgets(2));
    expect(find.text('Premium required'), findsNothing);

    await tester.tap(find.text('Right temple'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AttackDetailScreen), findsOneWidget);

    await finishTest(tester);
  });
}
