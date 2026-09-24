import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/app_config/domain/entities/app_config.dart';

import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/sync/domain/entities/sync_collection.dart';

import '../../helpers/pump_app.dart';

Future<void> _logAttack(PumpedApp app) => DriftAttackRepository(app.db).insert(
  Attack(
    id: 'a1',
    startedAt: DateTime.now().toUtc(),
    intensity: 5,
    regions: const <HeadRegion>[HeadRegion.templeL],
  ),
);

/// The gate replaces the whole app, so these guard the case that matters most: it must NOT appear for anybody the row does not name.
void main() {
  testWidgets('an address the row does not name reaches the app', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true);

    expect(find.text('Account locked'), findsNothing);
    expect(find.text('Log an attack'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('an anonymous session is never blocked', (tester) async {
    // Membership is by address, so a session that carries none matches
    // nothing — even with the list naming somebody.
    await pumpApp(
      tester,
      appConfig: AppConfig(blockedEmails: <String>{'tester@example.com'}),
    );

    expect(find.text('Account locked'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('a blocked address gets the screen instead of the app', (
    tester,
  ) async {
    await pumpApp(
      tester,
      signedIn: true,
      appConfig: AppConfig(blockedEmails: <String>{'tester@example.com'}),
    );

    expect(find.text('Account locked'), findsOneWidget);
    // Not a sheet over the app: the app underneath is gone.
    expect(find.text('Log an attack'), findsNothing);

    await finishTest(tester);
  });

  testWidgets('Sign out is what clears the block', (tester) async {
    final PumpedApp app = await pumpApp(
      tester,
      signedIn: true,
      appConfig: AppConfig(blockedEmails: <String>{'tester@example.com'}),
    );

    await tapVisible(tester, find.text('Sign out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(app.auth.signOutCalls, 1);

    await finishTest(tester);
  });

  // The account has been syncing, so its records are on this device: a bare
  // sign-out handed them to whoever signed in next.
  testWidgets(
    'signing out of a blocked account saves, then empties the device',
    (tester) async {
      final PumpedApp app = await pumpApp(
        tester,
        signedIn: true,
        appConfig: AppConfig(blockedEmails: <String>{'tester@example.com'}),
      );
      await _logAttack(app);

      await tapVisible(tester, find.text('Sign out'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        app.syncRemote.of(SyncCollection.attacks).values.map((r) => r.id),
        contains('a1'),
      );
      expect(await app.db.select(app.db.attacks).get(), isEmpty);
      expect(app.auth.signOutCalls, 1);

      await finishTest(tester);
    },
  );

  testWidgets('a record still owed keeps the blocked account signed in', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(
      tester,
      signedIn: true,
      appConfig: AppConfig(blockedEmails: <String>{'tester@example.com'}),
    );
    app.syncRemote.failPutAfter = 0;
    await _logAttack(app);

    await tapVisible(tester, find.text('Sign out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(app.auth.signOutCalls, 0);
    expect(await app.db.select(app.db.attacks).get(), hasLength(1));
    expect(find.textContaining('nothing has been removed'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('unblocking the row puts the app back without a restart', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(
      tester,
      signedIn: true,
      appConfig: AppConfig(blockedEmails: <String>{'tester@example.com'}),
    );

    expect(find.text('Account locked'), findsOneWidget);

    app.appConfig.emit(AppConfig.empty);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Account locked'), findsNothing);
    expect(find.text('Log an attack'), findsOneWidget);

    await finishTest(tester);
  });
}
