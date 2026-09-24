import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/sync/domain/entities/sync_collection.dart';

import '../../helpers/pump_app.dart';

/// Signing out hands this device's records back to the account and empties the
/// device — so the one thing that must never happen is emptying it while a
/// record is still owed to the server.
void main() {
  Future<void> openAccount(WidgetTester tester) async {
    await openSettings(tester);
    await tapVisible(tester, find.text('Account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> tapSignOut(WidgetTester tester) async {
    await tapVisible(tester, find.text('Sign out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // The button and the dialog's action carry the same label; the dialog is the later one.
    await tapVisible(tester, find.text('Sign out').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> logAttack(PumpedApp app) => DriftAttackRepository(app.db).insert(
    Attack(
      id: 'a1',
      startedAt: DateTime.now().toUtc(),
      intensity: 5,
      regions: const <HeadRegion>[HeadRegion.templeL],
    ),
  );

  testWidgets('it warns that the records leave this device', (tester) async {
    await pumpApp(tester, signedIn: true);
    await openAccount(tester);

    await tapVisible(tester, find.text('Sign out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The old copy promised the opposite — "your attacks stay on this device" — which is now the one thing that is not true.
    expect(find.textContaining('come off this device'), findsOne);

    await finishTest(tester);
  });

  testWidgets('signing out saves to the account, then empties the device', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester, signedIn: true);
    await logAttack(app);
    await openAccount(tester);

    await tapSignOut(tester);

    // The seeded medications are up there too; this is the record the test made.
    expect(app.syncRemote.stored[SyncCollection.attacks], contains('a1'));
    expect(await app.db.select(app.db.attacks).get(), isEmpty);
    expect(app.auth.signOutCalls, 1);

    await finishTest(tester);
  });

  // It sits outside the scaffold, so without a Material of its own its text
  // came out with Flutter's yellow "no Material" underline.
  testWidgets('the wait is a card over the screen, its text on a Material', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester, signedIn: true);
    await logAttack(app);
    await openAccount(tester);
    final Completer<void> hold = Completer<void>();

    app.syncRemote.holdPuts = hold;
    // Released even when an expect below fails, or the held write hangs the teardown for the full timeout.
    addTearDown(() {
      if (!hold.isCompleted) hold.complete();
    });

    await tapSignOut(tester);

    // The button carries the same words; the overlay's copy is the one centred over the barrier.
    final Finder message = find.descendant(
      of: find
          .ancestor(of: find.byType(ModalBarrier), matching: find.byType(Stack))
          .first,
      matching: find.text('Saving your data to your account…'),
    );

    expect(message, findsWidgets);
    expect(
      find.ancestor(of: message.last, matching: find.byType(Material)),
      findsWidgets,
    );
    expect(find.byType(ModalBarrier), findsWidgets);

    hold.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await finishTest(tester);
  });

  testWidgets('a record that never reached the server cancels the sign-out', (
    tester,
  ) async {
    final PumpedApp app = await pumpApp(tester, signedIn: true);
    // Offline from before the attack was logged, so the write-through push failed too and the record is still owed.
    app.syncRemote.failPutAfter = 0;
    await logAttack(app);
    await openAccount(tester);

    await tapSignOut(tester);

    // The device's copy is the only copy there is. Keeping the session is what keeps it reachable.
    expect(await app.db.select(app.db.attacks).get(), hasLength(1));
    expect(app.auth.signOutCalls, 0);
    expect(find.textContaining('Connect to the internet'), findsOne);

    await finishTest(tester);
  });
}
