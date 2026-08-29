import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';

import '../../helpers/pump_app.dart';

/// App Store 5.1.1(v): once accounts exist, deleting one has to be possible from inside the app.
void main() {
  Future<void> openAccount(WidgetTester tester) async {
    await openSettings(tester);
    await tapVisible(tester, find.text('Account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('the account screen offers deletion', (tester) async {
    await pumpApp(tester, signedIn: true);
    await openAccount(tester);

    expect(find.text('Delete account'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('it asks first, and cancelling deletes nothing', (tester) async {
    final app = await pumpApp(tester, signedIn: true);
    await DriftAttackRepository(app.db).insert(
      Attack(
        id: 'a1',
        startedAt: DateTime.now().toUtc(),
        intensity: 5,
        regions: const <HeadRegion>[HeadRegion.templeL],
      ),
    );
    await openAccount(tester);

    await tapVisible(tester, find.text('Delete account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The dialog must say the subscription is untouched: someone who assumes otherwise stops managing it and keeps being charged.
    expect(find.textContaining('does not cancel your subscription'), findsOne);

    await tapVisible(tester, find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(app.auth.deleteAccountCalls, 0);
    expect(await app.db.select(app.db.attacks).get(), hasLength(1));

    await finishTest(tester);
  });

  testWidgets('confirming wipes the device and deletes the account', (
    tester,
  ) async {
    final app = await pumpApp(tester, signedIn: true);
    await DriftAttackRepository(app.db).insert(
      Attack(
        id: 'a1',
        startedAt: DateTime.now().toUtc(),
        intensity: 5,
        regions: const <HeadRegion>[HeadRegion.templeL],
      ),
    );
    await openAccount(tester);

    await tapVisible(tester, find.text('Delete account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // Same words as the button that opened it, and the dialog is on top.
    await tester.tap(find.text('Delete account').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(app.auth.deleteAccountCalls, 1);
    // The device copy goes too — the account being gone is no help if the records are still sitting in the database.
    expect(await app.db.select(app.db.attacks).get(), isEmpty);

    await finishTest(tester);
  });
}
