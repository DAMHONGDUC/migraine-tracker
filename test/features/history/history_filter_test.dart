import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/data/repositories/drift_attack_repository.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_location.dart';

import '../../helpers/pump_app.dart';

Attack at(String id, DateTime local) => Attack(
  id: id,
  startedAt: local.toUtc(),
  intensity: 5,
  location: HeadLocation.left,
);

Future<void> openHistory(WidgetTester tester) async {
  await tester.tap(find.text('History'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Opens the filter bottom sheet from the app bar and picks [period].
Future<void> selectPeriod(WidgetTester tester, String period) async {
  await tester.tap(find.byIcon(Icons.filter_list));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text(period));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('the filter sheet narrows the list to the selected period', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    final repo = DriftAttackRepository(app.db);
    final now = DateTime.now();
    // One today, one ~10 days ago (out of "today"/"week", in "month"/"all").
    await repo.insert(at('today', DateTime(now.year, now.month, now.day, 9)));
    await repo.insert(at('old', now.subtract(const Duration(days: 10))));

    await openHistory(tester);

    // Default = All → both count.
    expect(find.text('2 attacks'), findsOneWidget);

    await selectPeriod(tester, 'Today');
    expect(find.text('1 attack'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('a period with no attacks shows the filtered empty state', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    final repo = DriftAttackRepository(app.db);
    await repo.insert(
      at('old', DateTime.now().subtract(const Duration(days: 40))),
    );

    await openHistory(tester);
    await selectPeriod(tester, 'Today');

    expect(find.text('No attacks in this period.'), findsOneWidget);

    await finishTest(tester);
  });

  testWidgets('the app bar toggle switches between list and chart modes', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await DriftAttackRepository(
      app.db,
    ).insert(at('a', DateTime.now().subtract(const Duration(hours: 2))));

    await openHistory(tester);
    expect(find.text('1 attack'), findsOneWidget); // list mode default

    await tester.tap(find.byIcon(Icons.bar_chart));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Attacks per week'), findsOneWidget); // chart mode

    await tester.tap(find.byIcon(Icons.list_alt));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1 attack'), findsOneWidget);

    await finishTest(tester);
  });
}
