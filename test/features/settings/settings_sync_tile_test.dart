import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';

import '../../helpers/pump_app.dart';

void main() {
  // The sync card at the top of Settings (owner's rule, 2026-09-24): it shows
  // what sync is doing, and it is still no control — sync stays automatic, and
  // `SyncScreen`, `/sync` and the old manual row stay deleted.
  testWidgets('signed out, Settings has no sync card', (tester) async {
    await pumpApp(tester);
    await openSettings(tester);

    expect(find.text('All saved'), findsNothing);
    expect(find.text('Syncing'), findsNothing);

    await finishTest(tester);
  });

  testWidgets(
    'signed in, the card sits above every group and says it is saved',
    (tester) async {
      await pumpApp(tester, signedIn: true);
      await openSettings(tester);
      await tester.pump(const Duration(seconds: 1));

      final Finder card = find.text('All saved');

      expect(card, findsOneWidget);
      expect(
        tester.getRect(card).top,
        lessThan(tester.getRect(find.text('General')).top),
      );
      // Still nothing to tap: the old manual row is what would come back first.
      expect(find.text('Sync data to cloud'), findsNothing);

      await finishTest(tester);
    },
  );

  // It said "uploads when online" while online, when the server was the one
  // refusing. Offline or refused, all it can honestly say is it will retry.
  testWidgets('a failed push says it will retry, not that you are offline', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester, signedIn: true);
    app.syncRemote.failPutAfter = 0;
    await DriftAttackRepository(app.db).insert(
      Attack(
        id: 'a1',
        startedAt: DateTime.now().toUtc(),
        intensity: 5,
        regions: const <HeadRegion>[HeadRegion.templeL],
      ),
    );
    // Past the write-through debounce, so the push has run and failed.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    await openSettings(tester);

    expect(find.text('1 change not saved'), findsOneWidget);
    expect(find.text('It will try again on its own'), findsOneWidget);

    await finishTest(tester);
  });
}
